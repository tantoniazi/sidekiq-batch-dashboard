# frozen_string_literal: true

namespace :sidekiq do
  desc "Run Sidekiq APM diagnostics (thread safety, config, Redis, concurrency)"
  task apm: :environment do
    require "sidekiq/batch/dashboard/storage/redis_store"
    require "sidekiq/batch/dashboard/storage/metrics_store"
    require "sidekiq/batch/dashboard/apm/worker_profiler"
    require "sidekiq/batch/dashboard/apm/stuck_job_detector"
    require "sidekiq/batch/dashboard/apm/thread_pool_analyzer"
    require "sidekiq/batch/dashboard/apm/redis_saturation_detector"
    require "sidekiq/batch/dashboard/diagnostics/concurrency_analyzer"
    require "sidekiq/batch/dashboard/diagnostics/thread_safety_checker"
    require "sidekiq/batch/dashboard/diagnostics/config_analyzer"

    puts "Sidekiq APM Diagnostics"
    puts "=" * 50

    config = Sidekiq::Batch::Dashboard::Diagnostics::ConfigAnalyzer.run
    if config[:issues].any?
      config[:issues].each { |i| puts "⚠ #{i}" }
    else
      puts "✓ Config: no issues"
    end

    concurrency = Sidekiq::Batch::Dashboard::Diagnostics::ConcurrencyAnalyzer.run
    if concurrency[:issues].any?
      concurrency[:issues].each { |i| puts "⚠ #{i}" }
    else
      puts "✓ Concurrency: OK"
    end

    redis = Sidekiq::Batch::Dashboard::Apm::RedisSaturationDetector.stats
    if redis[:latency_ms] > 50 && redis[:latency_ms] >= 0
      puts "⚠ High Redis latency: #{redis[:latency_ms]} ms"
    else
      puts "✓ Redis latency: #{redis[:latency_ms]} ms"
    end

    thread_safety = Sidekiq::Batch::Dashboard::Diagnostics::ThreadSafetyChecker.scan
    if thread_safety.any?
      thread_safety.each do |t|
        puts "⚠ Worker using unsafe pattern: #{t[:worker]}"
        t[:issues].each { |i| puts "  - #{i}" }
      end
    else
      puts "✓ Thread safety: no obvious issues"
    end

    stuck = Sidekiq::Batch::Dashboard::Apm::StuckJobDetector.scan
    if stuck.any?
      puts "⚠ Stuck jobs: #{stuck.size}"
      stuck.first(3).each { |s| puts "  #{s[:worker]} #{s[:jid]} running #{s[:running_sec]}s" }
    else
      puts "✓ Stuck jobs: none"
    end

    puts "=" * 50
    puts "Done. View full APM in Sidekiq Web → Dashboard / Diagnostics tabs."
  end
end
