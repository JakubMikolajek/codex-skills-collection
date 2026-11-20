---
name: embedded-connectivity
description: Connectivity patterns for embedded devices - Wi-Fi (including co-processor links such as ESP-Hosted), provisioning, MQTT client robustness (fragmented messages, ownership across queues, LWT, reconnect/backoff, TLS and time), CAN/TWAI with ISO-TP, and device-to-device secure links with counters. Covers task/queue boundaries, memory ownership, failure and offline behaviour, and contract alignment with the backend. Use when writing or reviewing device-side network, bus or protocol code. Load alongside esp-idf or c-embedded.
---

# Embedded Connectivity

A connected device spends most of its life in degraded conditions: no network, half-open sockets, a broker restart, a noisy bus, a peer on older firmware. Connectivity code is correct only if **every degraded state has a defined behaviour**.

## When to Use

- Wi-Fi bring-up, provisioning, reconnect logic, or a Wi-Fi co-processor (SDIO/SPI hosted slave)
- MQTT client code: topics, QoS, payload parsing, LWT, reconnect, TLS
- CAN/TWAI drivers, ISO-TP links, pairing/secure channels between devices
- Message formats shared with a backend or companion device
- "Works on the bench, fails in the field" network issues

## When NOT to Use

- Backend MQTT consumers, broker topology, routing keys — `message-queue` (BACKEND branch); load it for the contract side
- Update/signing/rollback details — `esp-idf-secure-ota`
- TLS policy, secrets, crypto review — `security-hardening`

## Core Principle

**Network and bus callbacks run on someone else's task with someone else's stack and timing. Copy what you need, hand it to your own task, and return.** Everything else in this skill follows from that.

## Delivery Workflow

```
Connectivity progress:
- [ ] Step 1: Define the state machine: states, events, timeouts, and behaviour OFFLINE
- [ ] Step 2: Define the message contract (topic/id, payload schema, version, size limits) with the other side
- [ ] Step 3: Define ownership and lifetime of every buffer crossing a task/queue
- [ ] Step 4: Define resource bounds (queue depth, max payload, retries, backoff)
- [ ] Step 5: Write failure-injection tests (disconnect mid-message, oversize, garbage, peer old version)
```

## Event Handlers and Task Boundaries

- MQTT/Wi-Fi/IP/esp_event handlers run on the library's task. Blocking there (a flash write, a mutex held by the UI, a synchronous request/response) stalls the whole stack and eventually triggers keepalive loss or watchdogs.
- Pattern: **handler → copy into owned buffer → bounded queue → application task**. Return in microseconds.
- Decide **queue-full behaviour** per stream: drop-oldest for telemetry, drop-newest + count for commands, never silent. A dropped *command* needs an error response or an alarm.
- Every item that carries a heap pointer needs a rule: *who frees it, on every path* (consumer done, queue full, disconnect, shutdown). Leaks in network code show up as slow memory decay over weeks.

## Wi-Fi and Co-Processors (ESP-Hosted etc.)

- Wi-Fi state is an **event-driven state machine**: `STA_START → CONNECTED → GOT_IP → LOST_IP/DISCONNECTED`. Upper layers (MQTT, OTA, NTP) start on `GOT_IP` and must **stop cleanly** on disconnect. Do not poll `is_connected` in loops.
- Reconnect with **exponential backoff + jitter**, capped; reset the backoff on a *stable* connection, not merely on connect. Reconnect storms from a fleet after an outage are a real operational hazard.
- Distinguish failure causes (auth fail, AP not found, no DHCP lease, captive portal) in logs/telemetry; they need different user messaging.
- With a **Wi-Fi co-processor** (host + slave chip), the link is a distributed system: separate firmware versions, a transport (SDIO/SPI/UART) with its own flow control and error modes, and a slave OTA. Define: handshake/version check, what the host does when the slave is missing or resets, recovery (re-init link without rebooting host), and logging that lets you see **which side** failed. See `esp-idf-secure-ota` for slave updates.
- High-priority transport tasks (RX loops, retry-with-1 ms-sleep loops) can starve app tasks on the same core; budget them and verify the CPU/IDLE headroom under traffic.
- Provisioning: protect the provisioning channel (security level with proof-of-possession/verifier); do not ship example credentials/salts; time-box the provisioning mode; clear credentials on factory reset (see `embedded-persistence`).
- Check regulatory/region settings (channels, power) are set from the product's market, not defaulted.

## MQTT

```c
case MQTT_EVENT_DATA: {
    // Messages may arrive FRAGMENTED: current_data_offset / data_len / total_data_len
    if (e->current_data_offset == 0) {
        reset_reassembly();                         // drop any stale partial message first
        if (e->total_data_len > MAX_RX_LEN || e->topic_len >= sizeof(rx.topic)) { reject(); break; }
        rx.buf = alloc(e->total_data_len + 1);      // check NULL -> drop + count
        memcpy(rx.topic, e->topic, e->topic_len); rx.topic[e->topic_len] = 0;
        rx.len = 0;
    }
    if (!rx.buf || e->current_data_offset + e->data_len > rx.cap) { abort_msg(); break; }
    memcpy(rx.buf + e->current_data_offset, e->data, e->data_len);
    rx.len += e->data_len;
    if (rx.len == e->total_data_len) { enqueue_or_free(&rx); }   // ownership moves to the consumer
    break;
}
case MQTT_EVENT_DISCONNECTED: reset_reassembly(); /* free partial buffer */ break;
```

Rules:

- **Bound everything from the wire**: topic length, payload length, JSON nesting/size, array counts. A cloud bug or hostile publisher must not be able to exhaust heap or overflow a fixed `topic[N]`.
- Reassembly state belongs to the MQTT task only; free partial messages on disconnect and when a new first fragment arrives.
- Parse on the **consumer task**, with a validated schema (type, range, enum) — treat payloads as untrusted even from your own backend (stale/buggy versions exist). Unknown fields are ignored; unknown versions rejected with a clear error response.
- **Idempotency**: QoS 1 can redeliver. Commands that open a lock, charge, or change state need a correlation/command id and a dedupe window; reply with the same result on redelivery.
- **LWT (testament)** published by the broker on ungraceful loss, plus an explicit `online` retained message on connect, gives the backend a reliable presence signal. Keep topic scheme `…/<device-id>/<channel>` consistent and versioned; document it in the shared contract (`api-contract`).
- Keepalive vs. NAT/mobile timeouts: choose deliberately; too long hides dead links, too short wastes power/data.
- **TLS**: validate server certs (CA bundle or pinned CA), mind the cost (RAM ≈ tens of KB per session, handshake CPU, stack size of the MQTT task), and **ensure wall-clock time is valid before the handshake** if certificate dates are checked (NTP sync/RTC) — otherwise "works only sometimes" after power loss.
- Publish from tasks through a bounded outbox; define what happens to events generated **while offline**: drop, coalesce, or persist and replay with timestamps and sequence numbers (and cap the backlog and flash wear — see `embedded-persistence`). "Skipped silently when disconnected" must be a documented choice, not an accident.
- On reconnect, publish **current state** (not only deltas) so the backend converges.
- Credentials per device; never log them or full payloads containing secrets (PINs, templates, tokens).

## CAN / TWAI and ISO-TP

- Single-frame limit is 8 bytes (classic CAN); anything longer needs a transport (ISO-TP/ISO 15765-2) with flow control: block size, STmin, and timeouts (N_As/N_Bs/N_Cr). Configure all timeouts, handle **abort/restart of a transfer** cleanly, and bound concurrent transfers.
- Handle bus errors explicitly: error-passive and **bus-off** with controlled recovery (and a counter), RX overflow, TX queue full. A device alone on the bus will see persistent TX failures (no ACK) — don't retry at full speed forever.
- Hardware acceptance filters keep irrelevant traffic out of the CPU; set them from the ID map, don't accept-all by default.
- ISR → queue → protocol task. The protocol task owns the state machine; application calls **enqueue commands and return** (return `ESP_ERR_NO_MEM`/busy on overflow), never block the caller waiting on the bus.
- Define ID allocation (per link/direction), endianness, and version in the pairing handshake; reject incompatible versions loudly.
- Shared protocol libraries copied into several projects (device + companions) must stay **byte-identical**: verify with a CI diff/checksum, bump the protocol version on any wire change, and test old↔new combinations.

## Secure Device-to-Device Links

- Pairing is a state machine with a **time window**, explicit user action on both ends, and a defined result on timeout/failure; it should replace previous bonds deliberately and say so in the UI.
- Derive session keys per link with labelled KDF contexts; never reuse the same key+nonce pair. Use authenticated encryption; include direction/link id in the nonce or AAD.
- Replay protection relies on **counters that survive reset and never move backwards** — see `embedded-persistence` (reserve-ahead) and review any save path that could overwrite a counter with a stale value.
- Rate-limit pairing and failed-auth attempts. Do not distinguish error causes to the peer more than necessary.
- Peer firmware updates over the link (CAN, UART): chunked, CRC'd, acknowledged, resumable or cleanly restartable, with a version/compat check before starting. See `esp-idf-secure-ota`.

## Time

- Devices need a trustworthy time source for TLS validity, schedules, audit logs and token expiry. Define the source (NTP, RTC, backend), the behaviour while unsynchronised (queue/skip time-dependent features, mark events "time unknown"), and handle time **jumps** (never compute durations from wall-clock; use monotonic time).
- Time-dependent access policies (schedules/time ranges) must define what happens **with no valid time**: fail closed or last-known, explicitly.

## Checklist

```
- [ ] State machine drawn: connect, steady, degraded, offline, recovery
- [ ] Handlers copy + enqueue; no blocking calls inside library callbacks
- [ ] Every queued pointer has an owner and a free path on all branches
- [ ] Fragmented MQTT messages reassembled with bounds; partial state reset on disconnect
- [ ] Topic/payload sizes bounded; schema validated on the consumer task
- [ ] Commands idempotent (correlation id + dedupe)
- [ ] LWT + online message; current state republished on reconnect
- [ ] TLS validated; time valid before handshake; RAM/stack for TLS budgeted
- [ ] Offline behaviour for events and commands documented and tested
- [ ] Reconnect backoff with jitter; no tight retry loops
- [ ] CAN: bus-off/error-passive handled; ISO-TP timeouts configured; filters set
- [ ] Shared protocol code identical across projects; versions in handshake
- [ ] Counters monotonic; pairing windowed and rate-limited
- [ ] Failure-injection tests: disconnect mid-message, oversize, malformed, old peer
```

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| Doing real work inside the MQTT/event handler | Copy, enqueue, return |
| `memcpy(topic, e->topic, e->topic_len)` into a fixed buffer without a check | Bound-check against buffer size |
| Assuming one `MQTT_EVENT_DATA` = one message | Reassemble by offset/total length |
| Static reassembly buffer never reset on disconnect | Reset on disconnect and on new first fragment |
| Dropping events silently when offline | Documented policy: drop/coalesce/persist+replay, counted |
| Executing a redelivered command twice | Correlation id + dedupe window |
| Infinite 1 ms retry loops after a link error | Backoff with jitter and a cap; escalate to link reset |
| TLS handshake with no valid time | Sync time first; handle failure by retrying later |
| Blocking the caller until the CAN peer replies | Enqueue command; async result event |
| Different copies of a shared protocol library drifting | Byte-identical + CI check + protocol version |
| Logging full payloads including credentials | Log ids/lengths; redact secrets |

## Connected Skills

- `esp-idf` — event loop, task priorities, memory placement for buffers
- `freertos` — queues, ownership, deadlock review
- `embedded-persistence` — offline backlog, counters, credentials
- `esp-idf-secure-ota` — slave/companion firmware updates
- `message-queue` — backend side of the device pipeline
- `api-contract` — shared topic/payload contract
- `security-hardening` — TLS, key handling, replay protection review
- `observability` — connectivity telemetry (reset reason, reconnect counts)
