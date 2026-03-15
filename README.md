# Sidekiq Batch Dashboard

A **mountable Rails Engine** that provides a production-ready **web UI for monitoring Sidekiq Batch jobs**. Sidekiq does not ship a native UI for batches; this dashboard lets you inspect batch progress, jobs, failures, and statistics.

## Stack

- **Ruby** 3.3+
- **Rails** 7 or 8
- **Sidekiq** + **sidekiq-batch**
- **Redis**
- **Bootstrap 5** (CDN)
- **Chart.js** (CDN)
- **ViewComponent** (optional, for progress bar and stats cards)

## Installation

Add to your application's Gemfile:

```ruby
gem "sidekiq-batch-dashboard"
```

Then:

```bash
bundle install
```

## Mounting the Engine

In your Rails app's `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount SidekiqBatchDashboard::Engine => "/batches"
end
```

You can use either:

- `SidekiqBatchDashboard::Engine` (alias)
- `Sidekiq::Batch::Dashboard::Engine`

Both point to the same engine. The dashboard will be available at **/batches** (or whatever path you choose).

## Requirements

- Your app must use **Sidekiq** and **sidekiq-batch** (or compatible batch implementation that uses Redis keys `BID-{bid}` and `BID-{bid}-failed`).
- Redis must be configured (e.g. via Sidekiq's Redis connection).

## Features

### 1. Batches list (`/batches`)

- Batch ID, description, total jobs, pending, failed, created at, status (running / complete / failed)
- Sorting: newest, oldest, by total jobs, by failures
- Filtering: all, running, complete, failed

### 2. Batch detail (`/batches/:id`)

- Description, total jobs, completed, pending, failures, success rate
- Progress bar
- Table of failed jobs (error message, worker, retry count)

### 3. Jobs page (`/jobs`)

- List of jobs from Retry and Dead sets (optionally filtered by batch)
- Columns: Job ID, worker class, arguments, queue, status, runtime

### 4. Failures page (`/failures`)

- Failed jobs with error message, worker class, retry count, arguments
- **Retry** action to re-enqueue a job

### 5. Progress page (`/progress`)

- Statistics cards: total batches, total jobs, completed, failed, success rate
- Chart.js charts:
  - Jobs processed (approximate) over the last 24 hours
  - Success vs failures (doughnut)

## Redis integration

Batch data is read from Redis (same store used by sidekiq-batch):

- **RedisBatchLoader** – fetches batch metadata and failed JIDs
- **RedisAdapter** – low-level access to keys `BID-{bid}` (hash) and `BID-{bid}-failed` (set)

The engine uses `Sidekiq.redis` for all Redis access, so it uses your existing Sidekiq configuration.

## Project structure (summary)

```
app/
  controllers/  batches, jobs, failures, progress
  models/       BatchInfo, BatchJob, BatchStat (value objects)
  services/     BatchInspector, BatchStatistics, RedisBatchLoader
  views/        batches, jobs, failures, progress
  components/   ProgressBarComponent, StatsCardComponent, ChartComponent
  assets/       stylesheets, javascripts (charts)
config/
  routes.rb
lib/
  sidekiq/batch/dashboard/
    engine.rb
    redis_adapter.rb
```

---

# Sidekiq APM (Observability platform inside Sidekiq Web)

The gem also provides a **full Sidekiq APM** embedded in the **Sidekiq Web UI**: concurrency, Redis, memory, stuck jobs, deadlocks, and diagnostics.

## APM installation

1. **Require the Web extension** after Sidekiq::Web (e.g. in `config/routes.rb` or an initializer):

```ruby
# config/routes.rb
require "sidekiq/web"
require "sidekiq/batch/dashboard/web"  # adds APM tabs to Sidekiq Web

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  mount SidekiqBatchDashboard::Engine => "/batches"  # optional: standalone batch UI
end
```

2. **Add server middleware** so every job is instrumented (in `config/initializers/sidekiq.rb` or where you configure Sidekiq):

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Batch::Dashboard::Middleware::Instrumentation
    chain.add Sidekiq::Batch::Dashboard::Middleware::RuntimeMonitor
    chain.add Sidekiq::Batch::Dashboard::Middleware::ErrorCapture
  end
end
```

3. Open **/sidekiq** and use the new tabs: **Dashboard**, **Workers**, **Failures**, **Logs**, **Concurrency**, **Redis**, **Memory**, **Diagnostics**.

## APM tabs (inside Sidekiq Web)

| Tab | Description |
|-----|-------------|
| **Dashboard** | Overview: Redis latency, thread pool, stuck jobs, memory leak suspects, top slow workers |
| **Workers** | Top slow workers, throughput by queue |
| **Failures** | Captured job errors (from middleware), including swallowed errors |
| **Logs** | Recent error log entries |
| **Concurrency** | Thread pool usage, queue backlog, saturation warning |
| **Redis** | Redis latency and memory |
| **Memory** | Workers with possible memory growth (avg increase per run above threshold) |
| **Diagnostics** | Stuck jobs, possible deadlocks, thread-safety warnings, config issues |

## Rake diagnostics

Run static and runtime diagnostics from the command line:

```bash
bundle exec rake sidekiq:apm
```

Example output:

```
Sidekiq APM Diagnostics
==================================================
⚠ Redis pool size (5) may be too small for concurrency
✓ Concurrency: OK
✓ Redis latency: 0.42 ms
⚠ Worker using unsafe pattern: MyWorker
  - Worker uses class variable (not thread-safe)
✓ Stuck jobs: none
==================================================
```

## APM features (summary)

- **Instrumentation middleware**: records worker, jid, queue, start/end, duration, memory before/after, thread id, retry count, batch id.
- **Metrics store**: batched writes, TTL, sampling; low Redis overhead.
- **Memory leak detection**: flags workers where average memory increase per execution exceeds threshold.
- **Stuck job detection**: jobs running longer than 5× average (or 60s minimum) are marked stuck.
- **Deadlock heuristics**: jobs running > 120s reported as possible deadlocks.
- **Redis saturation**: latency and memory; high latency warning.
- **Thread pool analyzer**: active vs concurrency, queue backlog, saturation warning.
- **Error capture**: job errors (and optional swallowed errors) stored with worker/jid/queue.
- **Thread-safety checker**: static checks for class variables, global state, unsafe memoization.
- **Config analyzer**: concurrency vs pool size, high concurrency warning.

## Performance and security

- **Redis**: Batched metric writes, TTL on keys, optional sampling to reduce overhead.
- **Security**: Job arguments are not stored in APM payloads by default; error messages are truncated; list sizes and payload sizes are limited (see `Storage::RedisStore`).

## Compatibility

- **Ruby** 3+
- **Rails** 6+, 7+, 8
- **Sidekiq** 6+, 7+

## Project structure (APM)

```
lib/sidekiq/batch/dashboard/
  web_extension.rb       # Sinatra routes for APM tabs
  web.rb                 # require + Sidekiq::Web.register
  middleware/
    instrumentation.rb  # duration, memory, jid, queue, batch_id
    error_capture.rb    # record job errors
    runtime_monitor.rb  # track running jobs (for stuck detection)
  apm/
    worker_profiler.rb
    memory_leak_detector.rb
    stuck_job_detector.rb
    deadlock_detector.rb
    redis_saturation_detector.rb
    thread_pool_analyzer.rb
  diagnostics/
    concurrency_analyzer.rb
    thread_safety_checker.rb
    config_analyzer.rb
  storage/
    redis_store.rb      # TTL, batched, size limits
    metrics_store.rb    # job metrics, worker stats
web/
  views/                # ERB for each tab
  assets/apm/
lib/tasks/
  sidekiq_apm.rake     # rake sidekiq:apm
```

## Security

In production, protect both the mountable engine and Sidekiq Web (including APM tabs) with your own authentication/authorization. The gem does not enforce authentication.

## License

MIT.
