---
name: esp-idf-secure-ota
description: Production security and update lifecycle for ESP-IDF devices. Covers partition tables, secure boot v2 (RSA/ECDSA), flash encryption (development vs release), eFuse irreversibility, signed and encrypted OTA images, app rollback and anti-rollback, version policy for dev builds, key handling in build/sign pipelines, and updating secondary processors (ESP-Hosted slave, CAN companions). Use when changing partitions, OTA code, signing/release scripts, or security-related sdkconfig. Load alongside esp-idf and security-hardening.
---

# ESP-IDF Secure Boot, Flash Encryption and OTA

On a shipped device, **a mistake here is permanent**: eFuses cannot be unburned, a wrong signing scheme can make every device reject every future update, and a missing rollback path turns a bad release into a field recall. This skill is a checklist-driven way to change this area without bricking fleets.

## When to Use

- Editing `partitions.csv`, OTA download/apply code, or version comparison logic
- Changing secure boot, flash encryption, signing scheme, rollback or download-mode sdkconfig
- Writing or reviewing build/sign/flash scripts and release pipelines
- Adding firmware update for a second processor (ESP-Hosted slave, CAN/UART companions)
- Reviewing a release for "can this brick a device?"

## When NOT to Use

- General ESP-IDF structure/memory/tasks — `esp-idf`
- Backend OTA server design — BACKEND branch; this skill covers the device side and the signing contract
- Generic secrets/TLS policy — `security-hardening` (load alongside)

## Core Principle

**Every release must be installable by the previous release, verifiable by the bootloader, and revertible if it fails to start.** If any one of the three is unproven on real hardware in the **release** configuration, do not ship.

## Delivery Workflow

```
Secure-OTA progress:
- [ ] Step 1: Identify the device state this change affects (dev-mode vs release-mode eFuses, fielded firmware versions)
- [ ] Step 2: Write down the update path: old release -> new release (signature scheme, image format, partition sizes)
- [ ] Step 3: Prove install + boot + rollback on a release-configured unit (not only a dev board)
- [ ] Step 4: Verify signing keys/eFuse digests used in CI match the fleet
- [ ] Step 5: Confirm a failed update leaves the device bootable and updatable
- [ ] Step 6: Record the release artifacts (signed binary, ELF, version, hashes)
```

## Partition Table

```csv
# Name,   Type, SubType, Offset,   Size,     Flags
nvs,      data, nvs,     0x10000,  24K,
otadata,  data, ota,     0x16000,  8K,       encrypted
phy_init, data, phy,     0x18000,  4K,       encrypted
nvs_keys, data, nvs_keys,0x19000,  4K,       encrypted
ota_0,    app,  ota_0,   0x20000,  0x7A0000, encrypted
ota_1,    app,  ota_1,   0x7C0000, 0x7A0000, encrypted
cfg,      data, spiffs,  0x1C20000,10M,      encrypted
```

- Sizes/offsets must respect alignment (app partitions on 64 KB boundaries for mmap; secure-boot/encryption may add alignment requirements). Check the build output, not only your arithmetic.
- **Two equal app slots** (`ota_0`/`ota_1`) + `otadata` are required for rollback. App growth is bounded by the slot: add a CI size gate with headroom (e.g. fail at 90 %) — hitting the limit forces a repartition, which cannot be done over the air safely.
- Mark data partitions that hold secrets, credentials, user data or keys `encrypted` when flash encryption is on. NVS encryption needs an `nvs_keys` partition.
- A coredump partition (if you want field crash dumps) must exist **before** release; adding it later is a partition-table change on fielded devices. Decide this early. With flash encryption the dump is written encrypted; decode with the project's ELF.
- Changing the partition table or its offset on fielded devices is not an OTA operation unless the bootloader/OTA code explicitly supports it. Treat the layout as frozen after first customer shipment; plan headroom up front.
- Keep `CONFIG_PARTITION_TABLE_MD5` on so a corrupt table is detected.

## Secure Boot v2

- Chips and IDF versions support RSA and/or ECDSA schemes. The scheme is chosen at build time **and the verification on device uses the scheme the running firmware was built with**.
- **Pitfall that bricks OTA**: an app built with the RSA scheme verifying images signed with ECDSA (or vice versa) rejects every update. Guard it in CMake with a `FATAL_ERROR` on the expected symbol (e.g. `CONFIG_SECURE_SIGNED_APPS_ECDSA_V2_SCHEME`) so a regenerated sdkconfig cannot silently flip it.
- Public key digest(s) are burned in eFuse (up to 3 key slots on supporting chips) — plan **key revocation/rotation** before shipping: which slot holds which key, how a compromised key is revoked, how many rotations remain.
- Verify on boot (`SECURE_SIGNED_ON_BOOT`) and on update (`SECURE_SIGNED_ON_UPDATE`). Keep the bootloader signed too; the ROM verifies the bootloader.
- Signing keys: generated once, stored offline / in HSM or CI secret store, backed up, never in the repo, never on the build machines of individual developers in production flows. Dev keys and production keys must differ, and a dev-signed image must not be accepted by release devices.
- Do not print, upload or paste private key material or eFuse key blocks into logs/tickets/chats.

## Flash Encryption

- **Development mode** allows re-flashing over UART with a limited counter of re-enables; **Release mode** is the production setting: UART/ROM download can be disabled, key readout disabled, flash can only be modified by signed/encrypted OTA. In release mode a mistaken partition or signature configuration may be unrecoverable.
- Typical release hardening set (confirm each symbol exists in the pinned IDF version): flash encryption release mode, key source eFuse, ROM download mode disabled (`CONFIG_SECURE_DISABLE_ROM_DL_MODE`), JTAG disabled/permanently disabled, UART bootloader log level none.
- Because eFuses are one-time: provisioning scripts (`first_program_*`, `encrypt_flash_*`) must be **idempotent where possible, dry-run capable, and print which eFuses they will burn before burning**. Test them on sacrificial units. Keep an inventory of per-unit eFuse state.
- Once encryption is on, anything written by esptool "plain" is garbage on boot. Provisioning flows must pre-encrypt images (`espsecure.py encrypt_flash_data` / equivalent) for the first flash when using external key flow, or let the device encrypt on first boot, and the script must be explicit about which.
- Reading encrypted data partitions through `mmap` works but has performance and cache implications — see `esp-idf` (cache-disabled operations) and `embedded-persistence`.

## OTA Image Pipeline

Stages and failure modes, in order:

1. **Version decision** — compare running vs offered version (`esp_app_desc_t.version`, semantic compare, not string compare). Define behaviour for equal/older (reject/allow downgrade only if intentionally supported and anti-rollback permits).
   - **Dev builds** should carry a version no OTA server will consider "older" (e.g. 255.0.0) so a server never overwrites a developer's device automatically; make this impossible to forget (CMake preset sets it).
2. **Transport** — HTTPS with certificate validation (bundle or pinned CA); system time must be valid before TLS if validity dates are checked. Enforce a total timeout and stall timeout; surface progress.
3. **Decrypt (optional transport encryption)** — encrypted-image schemes (`esp_encrypted_img`) decrypt in a pre-encrypted-data callback. Remember to **abort/free** the decrypt handle on every error path (leaks and half-open state are a classic).
4. **Header validation before write** — as soon as the first block containing `esp_app_desc_t` is available, validate project name, version, chip revision, secure version. Abort **before** erasing/writing the other slot when it is rejected.
5. **Write to the inactive slot** — never the running one. Do not unregister watchdogs globally; yield between chunks; run on a task with an internal-RAM stack (flash operations).
6. **Verify** — signature/digest verification by IDF at `esp_ota_end`/`esp_https_ota_finish`. Check `esp_https_ota_is_complete_data_received` so a truncated download is not accepted.
7. **Set boot partition** and reboot **only after** success; never reboot while storage writes are in flight (flush first, see `embedded-persistence`).
8. **Self-test and confirm** (below).

## Rollback and Anti-Rollback

```c
// App rollback enabled (CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE):
// the new app boots in state PENDING_VERIFY. If it resets before confirming, the bootloader reverts.
void on_boot(void) {
    esp_ota_img_states_t st;
    const esp_partition_t *run = esp_ota_get_running_partition();
    if (esp_ota_get_state_partition(run, &st) == ESP_OK && st == ESP_OTA_IMG_PENDING_VERIFY) {
        // run self-test: storage mounts, network stack up, critical peripherals respond,
        // and (important) the *update path itself* is alive
        if (self_test_ok()) esp_ota_mark_app_valid_cancel_rollback();
        else                esp_ota_mark_app_invalid_rollback_and_reboot();
    }
}
```

- The confirm point must be **late enough to prove the app works** (storage, comms, the ability to receive another update) and **early enough** that a normal slow boot does not hit the bootloader WDT. Never confirm unconditionally at the first line of `app_main`.
- A new image that boots, confirms, and then cannot update itself again is the worst failure. The self-test must include whatever the update mechanism needs.
- **Anti-rollback** (`BOOTLOADER_APP_ANTI_ROLLBACK` + a monotonically increasing `secure_version` in eFuse) prevents installing older, vulnerable images but is also irreversible: a bad secure_version bump permanently blocks all older images, including your known-good fallback. Bump it only for security fixes, in a deliberate release, after proving the new image.
- Define a retry/backoff policy for failed updates so a device does not loop download → fail → download and drain battery/bandwidth or hammer the server.

## Secondary Processors (ESP-Hosted slave, CAN/UART companions)

- A separate chip's firmware is a **second OTA with its own failure modes**. Document: image format, who verifies it, how the host learns the version, what happens on interrupted transfer, whether the companion can roll back.
- Keep the host and companion firmware **version-compatible by contract** (protocol version in the handshake). Refuse to run features across incompatible versions rather than failing mysteriously.
- Updating the companion over a slow link (CAN, UART) needs chunk acknowledgements, CRC per chunk and over the whole image, resume or clean restart, timeout on every ack, and a state machine that returns to a safe idle state on any error.
- Ship the companion image as a **versioned artifact in the host build** (e.g. `network_adapter.bin`) and record its hash in release notes; a host release that embeds a stale companion binary is easy to ship by accident.
- Provisioning a first-time companion (initial flash of the slave) is a manufacturing step with its own script — keep it documented and separate from the OTA path.

## Release Pipeline

- Build release from a **clean** tree with the **release preset**; archive: signed app, bootloader, partition table, ELF, map, `sdkconfig` resolved file, version, SHA-256 of each.
- The signing step is separate from the build step; the signing key is injected from a secret store, and the script verifies the signature after signing (`espsecure.py verify_signature` or equivalent).
- Gate: scripted check that the release sdkconfig has the required security symbols and that the version is greater than the last released one.
- Test matrix before staged rollout: fresh unit (factory-flashed), previous release → new, previous-previous → new (skipped release), update interrupted at 10/50/99 %, power cut during write, corrupted image, wrong-signature image, older-version image, rollback on failing self-test.
- Staged rollout with a kill switch on the server side; monitor reset-reason and update-failure telemetry before widening.

## Checklist

```
Partitions:
- [ ] Two OTA slots equal size; size gate in CI with headroom
- [ ] Secret-bearing data partitions marked encrypted; nvs_keys present if NVS encrypted
- [ ] Coredump partition decision made before first shipment
- [ ] Layout frozen after first shipment; changes planned as a migration

Signing/eFuse:
- [ ] Signature scheme guarded in CMake; matches fielded devices
- [ ] Key slots / revocation plan documented; keys not in repo or logs
- [ ] eFuse-burning scripts show what they burn; tested on sacrificial units
- [ ] Dev and release keys/policies are separate

OTA code:
- [ ] Semantic version compare; dev builds use a non-downgradable version
- [ ] TLS validated; time sane; timeouts set
- [ ] Header validated before the inactive slot is written
- [ ] Decrypt/OTA handles freed on every error path
- [ ] Truncated download rejected; reboot only after success and flush

Rollback:
- [ ] Rollback enabled; confirm only after a real self-test
- [ ] Self-test includes the update path
- [ ] Anti-rollback bump is a deliberate, reviewed decision

Release:
- [ ] Signed artifacts + ELF + resolved sdkconfig archived
- [ ] Update matrix executed on release-configured hardware
- [ ] Staged rollout and telemetry in place
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Testing OTA only on dev-mode boards | Test on a release-configured, eFuse-burned unit |
| `esp_ota_mark_app_valid_cancel_rollback()` at the top of `app_main` | Confirm after a self-test that includes the update path |
| Letting a regenerated sdkconfig change the signing scheme | CMake `FATAL_ERROR` guard on the scheme symbol |
| String comparison of versions | Parse and compare numerically |
| Writing the new image before validating its header | Validate the app descriptor from the first block, abort early |
| Skipping `is_complete_data_received` | Reject partial downloads |
| One mega scripted step "provision device" burning eFuses silently | Explicit, dry-run-able steps that print eFuse effects |
| Signing on developer laptops with the production key | Sign in CI / secured host; verify signature after signing |
| Bumping anti-rollback `secure_version` casually | Only for security fixes, after verification, with a fleet plan |
| Shipping host firmware with an unrecorded companion binary | Version + hash the embedded companion image |
| Adding a partition or moving offsets "just for this release" | Plan layout early; treat changes as migrations |

## Connected Skills

- `esp-idf` — sdkconfig discipline, memory/cache rules for OTA tasks
- `embedded-persistence` — flush and migrate data around updates
- `embedded-connectivity` — TLS/MQTT command channel that triggers updates
- `embedded-debugging` — reset-reason telemetry after rollouts
- `security-hardening` — key custody, TLS, secrets in logs
- `ci-cd` — release pipeline and artifact retention
- `migration-strategy` — data/schema compatibility across firmware versions
