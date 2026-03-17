---
name: performance-profiling
description: Performance profiling and optimization patterns for backend services, frontend applications, and systems-level code. Covers flamegraph analysis, memory profiling, latency budgeting, bottleneck identification, and per-ecosystem tooling (Node.js/clinic.js, Python/py-spy, Rust/cargo-flamegraph, browser DevTools). Use when a service is slow, memory usage is growing, latency SLOs are being missed, or before optimizing anything without a measured baseline.
---

# Performance Profiling

Measure first. Optimize second. Every optimization that is not preceded by a measurement is a guess dressed as an improvement.

## When to Use

- A service is missing latency SLOs (p95/p99 thresholds)
- Memory usage grows over time (suspected leak)
- A specific operation is "slow" but the cause is unknown
- Before any optimization work — to establish a baseline and confirm the bottleneck
- After a deploy that introduced a performance regression
- CodePath/IDE features with latency requirements (LSP response, indexing, PSI traversal)

## When NOT to Use

- Premature optimization before the feature is functionally correct
- Micro-benchmarking syntax choices without a production workload profile
- Tuning without a measurable target — always define the SLO before profiling

## Core Principles

### The Golden Rule: Never Optimize Without a Baseline

Before touching code, answer:
- What is the current measured performance? (p50, p95, p99 latency, or MB/s, or memory at t+1h)
- What is the target? (SLO, user expectation, or "2x faster than current")
- Which operation is the bottleneck? (profile first — the slow part is rarely where you expect)

### Amdahl's Law in Practice

Optimizing a section that accounts for 5% of runtime cannot improve total time by more than 5%, no matter how fast you make it. Profile to find the part that accounts for 80%+ of runtime. That is the only part worth optimizing.

### Performance Budget per Layer

Define budgets before profiling so you know when you are done:

| Layer | Target | Hard limit |
|---|---|---|
| API response (p99) | <200ms | <1s |
| Database query | <10ms | <100ms |
| Background job | <5s | <30s |
| LSP response (IDE) | <50ms | <200ms |
| Page interactive (LCP) | <2.5s | <4s |
| Memory growth per hour | 0 (stable) | <10MB/h |

## Profiling Process

```
Profiling progress:
- [ ] Step 1: Define the target and establish the baseline measurement
- [ ] Step 2: Isolate the workload to profile
- [ ] Step 3: Run the profiler for your ecosystem
- [ ] Step 4: Read the flamegraph or profile output
- [ ] Step 5: Identify the bottleneck (not the symptom)
- [ ] Step 6: Make one change, re-measure
- [ ] Step 7: Document findings
```

**Step 1: Define the target and establish the baseline**

```bash
# HTTP endpoint — establish baseline with wrk or k6
wrk -t4 -c100 -d30s http://localhost:3000/api/documents

# Single operation — time it explicitly
time curl -s http://localhost:3000/api/search?q=test > /dev/null

# Memory baseline — measure at steady state
# Node.js
node --expose-gc -e "setInterval(() => { global.gc(); console.log(process.memoryUsage().heapUsed / 1024 / 1024, 'MB') }, 5000)"
```

Record: p50, p95, p99, requests/sec, error rate, and memory at steady state. This is your before number. You cannot prove improvement without it.

**Step 2: Isolate the workload**

Profile under realistic load, not idle. An idle profile shows you nothing. Options:
- Replay production traffic (best)
- Synthetic load matching production request distribution
- Targeted microbenchmark of the suspected slow path (acceptable for known bottlenecks)

Avoid: profiling with a single sequential request — it misses lock contention, connection pool saturation, GC pressure.

**Step 3: Run the profiler for your ecosystem**

See ecosystem-specific sections below.

**Step 4: Read the flamegraph**

A flamegraph shows call stacks over time. The x-axis is time (wider = more time spent). The y-axis is call depth (bottom = entry point, top = leaf).

What to look for:
- **Wide bars near the top of the stack** — these are where time is actually spent, not just passing through
- **Flat plateaus** — a function that is wide because it calls nothing (pure compute) vs wide because it calls many small things
- **Unexpected library frames** — serialization, regex, JSON.parse, GC appearing prominently
- **I/O wait** — in async profiles, time blocked waiting for network or disk

What to ignore:
- Very narrow bars — they are not your problem
- Framework scaffolding near the bottom of the stack

**Step 5: Identify the bottleneck type**

| Symptom | Likely bottleneck | First check |
|---|---|---|
| High CPU, slow requests | Compute-bound | Flamegraph for hot function |
| Low CPU, slow requests | I/O-bound | Async trace for blocking calls |
| Growing memory | Memory leak | Heap snapshot diff |
| Fast p50, slow p99 | Lock contention or GC | p99 histogram + GC log |
| Slow after warm-up period | Connection pool exhaustion | Pool metrics |
| Slow only under load | N+1 query or missing index | Query count per request |

**Step 6: Make one change, re-measure**

Change exactly one thing. Re-run the same load test or benchmark. Compare to baseline. If improvement is less than 10%, the change is not meaningful enough to ship for performance reasons alone.

**Step 7: Document findings**

```markdown
## Performance Investigation — [service] — [date]

### Baseline
- Operation: GET /api/search
- p50: 45ms, p95: 210ms, p99: 890ms
- Load: 100 concurrent, 30s

### Bottleneck Found
- Location: `SearchService.buildQuery` (40% of request time)
- Type: N+1 — executing one DB query per tag in the filter array
- Evidence: flamegraph shows `pg.query` called 8-12x per request

### Change Made
- Rewrote to single JOIN query with array parameter

### Result
- p50: 12ms (-73%), p95: 48ms (-77%), p99: 95ms (-89%)
- No regression in correctness tests
```

## Ecosystem-Specific Tooling

### Node.js / TypeScript

**clinic.js** — all-in-one profiler for Node.js:
```bash
npm install -g clinic

# CPU profile + flamegraph
clinic flame -- node server.js
# Under load: clinic flame --autocannon -- node server.js

# I/O bottleneck analysis (blocked event loop)
clinic bubbleprof -- node server.js

# Memory leak detection
clinic heapprofiler -- node server.js
```

**Built-in V8 profiler** (no dependencies):
```bash
node --prof server.js
# Run load...
node --prof-process isolate-*.log > profile.txt
```

**Memory heap snapshot** (for leak investigation):
```typescript
import v8 from 'v8';
// Take two snapshots minutes apart under load, diff with Chrome DevTools Memory tab
v8.writeHeapSnapshot('/tmp/heap-t0.heapsnapshot');
```

**Key metrics to watch:**
- `process.memoryUsage().heapUsed` — actual JS heap
- `process.memoryUsage().rss` — total resident memory (includes native)
- `process.memoryUsage().external` — Buffer/ArrayBuffer outside heap
- Event loop lag via `perf_hooks`:
```typescript
import { monitorEventLoopDelay } from 'perf_hooks';
const h = monitorEventLoopDelay({ resolution: 10 });
h.enable();
setInterval(() => console.log('EL lag p99:', h.percentile(99), 'ms'), 5000);
```

### Python

**py-spy** — sampling profiler, attaches to running process (no code changes):
```bash
pip install py-spy

# Live flamegraph of running process
py-spy top --pid <PID>

# Record flamegraph to SVG
py-spy record -o flamegraph.svg --pid <PID>

# Profile from start
py-spy record -o flamegraph.svg -- python app.py
```

**scalene** — CPU + memory + GPU, line-level granularity:
```bash
pip install scalene
scalene app.py
# Opens browser with line-level CPU/memory breakdown
```

**memory_profiler** — line-level memory for leak hunting:
```python
from memory_profiler import profile

@profile
def my_function():
    ...
```

**cProfile** — built-in, good for call count analysis:
```bash
python -m cProfile -o profile.stats app.py
python -c "import pstats; p = pstats.Stats('profile.stats'); p.sort_stats('cumulative'); p.print_stats(20)"
```

**Async profiling** (FastAPI/asyncio):
```bash
pip install pyinstrument
# Middleware-based profiling for FastAPI
```

### Rust

**cargo-flamegraph** — CPU flamegraph:
```bash
cargo install flamegraph
# Requires perf (Linux) or DTrace (macOS)
cargo flamegraph --bin myapp
# Generates flamegraph.svg
```

**criterion** — statistical microbenchmarking:
```rust
use criterion::{criterion_group, criterion_main, Criterion};

fn bench_psi_traversal(c: &mut Criterion) {
    c.bench_function("psi_traverse_10k_nodes", |b| {
        b.iter(|| traverse_tree(&tree))
    });
}

criterion_group!(benches, bench_psi_traversal);
criterion_main!(benches);
```

```bash
cargo bench
# Outputs: time: [12.3 µs 12.5 µs 12.7 µs] — min/mean/max with statistical confidence
```

**Memory profiling**:
```bash
# heaptrack (Linux)
heaptrack ./target/release/myapp
heaptrack_gui heaptrack.myapp.gz

# valgrind massif (cross-platform)
valgrind --tool=massif ./target/release/myapp
ms_print massif.out.* | head -30
```

**DHAT** (heap allocation profiler, built into Rust via valgrind):
```bash
cargo install dhat
# Add dhat feature to Cargo.toml, annotate main with #[global_allocator]
valgrind --tool=dhat ./target/release/myapp
```

### Browser / Frontend

**Chrome DevTools Performance tab:**
1. Open DevTools → Performance
2. Enable "CPU throttling: 4x slowdown" for realistic mobile simulation
3. Record while performing the slow operation
4. Read the flame chart: long tasks (>50ms) are red
5. Check "Bottom-up" view for total time per function

**Lighthouse CLI** (Core Web Vitals):
```bash
npm install -g lighthouse
lighthouse https://myapp.com --output=html --output-path=report.html
```

**web-vitals library** (production measurement):
```typescript
import { onLCP, onINP, onCLS } from 'web-vitals';
onLCP(metric => console.log('LCP:', metric.value));
onINP(metric => console.log('INP:', metric.value));
```

**Bundle analysis:**
```bash
# webpack
webpack --profile --json > stats.json
# Upload to https://webpack.github.io/analyse/

# Vite
vite build --mode analyze  # with rollup-plugin-visualizer
```

## Common Bottlenecks by Type

### N+1 Query Problem
**Symptom**: p99 is 10x p50, slow under load, fast in isolation
**Detection**: count SQL queries per request (log all queries in dev, use query count assertion in tests)
**Fix**: JOIN, batch fetch with IN clause, or DataLoader pattern

### Missing Database Index
**Symptom**: query time grows linearly with table size
**Detection**: `EXPLAIN ANALYZE` shows Seq Scan on large table
**Fix**: `CREATE INDEX CONCURRENTLY` on the filtered/sorted column(s)

### Synchronous I/O in Async Context (Node.js / Python)
**Symptom**: high event loop lag, requests queue behind each other
**Detection**: clinic bubbleprof shows blocked I/O; py-spy shows thread blocked on I/O syscall
**Fix**: replace `fs.readFileSync` with async version; use `asyncio.to_thread` for blocking calls

### Memory Leak
**Symptom**: RSS grows 5-20MB/h, GC pressure increases over time, p99 degrades after hours
**Detection**: heap snapshot diff (take two snapshots 10 min apart under load; diff in Chrome DevTools)
**Common causes**: event listeners not removed, closures holding references, unbounded caches, global Maps/Sets

### JSON Serialization Hot Path
**Symptom**: flamegraph shows `JSON.stringify` or `json.dumps` as wide bars at top
**Fix**: replace with faster serializer (`fast-json-stringify` with schema, `orjson` for Python), cache serialized results, reduce payload size

## Anti-Patterns to Avoid

| Anti-Pattern | Instead Do |
|---|---|
| "It feels slow, let me add a cache" | Profile first — cache the right thing |
| Optimize p50 when p99 is the SLO | Profile under load to find the p99 tail |
| Profile with a single sequential request | Profile under realistic concurrent load |
| Benchmark with `Date.now()` diff | Use dedicated benchmark tools (criterion, wrk, k6) |
| Optimize without a before measurement | Always record baseline before changing anything |
| Premature memoization everywhere | Memoize only after profiling shows the cost |

## Connected Skills

- `sql-and-database` — query performance, EXPLAIN ANALYZE, index design
- `observability` — production latency metrics (p95/p99) feed into profiling investigations
- `rust` — Rust-specific performance patterns (allocation avoidance, SIMD, cache locality)
- `python` — Python async profiling, asyncio blocking patterns
- `debug-trace` — performance regression that appeared suddenly needs root cause analysis first
