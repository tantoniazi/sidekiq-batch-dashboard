# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Registers APM tabs and routes with Sidekiq::Web (Sinatra).
      module WebExtension
        ROOT = File.expand_path("../../../../web", __FILE__)

        def self.registered(app)
          app.get "/apm_dashboard" do
            @stats = WebExtension.dashboard_stats
            WebExtension.render_erb("dashboard", binding)
          end

          app.get "/apm_workers" do
            @slow = Apm::WorkerProfiler.top_slow_workers(limit: 50)
            @throughput = Apm::WorkerProfiler.throughput_by_queue
            WebExtension.render_erb("workers", binding)
          end

          app.get "/apm_failures" do
            @failures = Storage::RedisStore.read_list("errors", limit: 200)
            WebExtension.render_erb("failures", binding)
          end

          app.get "/apm_logs" do
            @logs = Storage::RedisStore.read_list("errors", limit: 100)
            WebExtension.render_erb("logs", binding)
          end

          app.get "/apm_concurrency" do
            @pool = Apm::ThreadPoolAnalyzer.stats
            WebExtension.render_erb("concurrency", binding)
          end

          app.get "/apm_redis" do
            @redis = Apm::RedisSaturationDetector.stats
            WebExtension.render_erb("redis", binding)
          end

          app.get "/apm_memory" do
            @leaks = Apm::MemoryLeakDetector.scan
            WebExtension.render_erb("memory", binding)
          end

          app.get "/apm_diagnostics" do
            @concurrency = Diagnostics::ConcurrencyAnalyzer.run
            @thread_safety = Diagnostics::ThreadSafetyChecker.scan
            @config = Diagnostics::ConfigAnalyzer.run
            @stuck = Apm::StuckJobDetector.scan
            @deadlocks = Apm::DeadlockDetector.scan
            WebExtension.render_erb("diagnostics", binding)
          end
        end

        def self.dashboard_stats
          {
            slow_workers: Apm::WorkerProfiler.top_slow_workers(limit: 10),
            stuck: Apm::StuckJobDetector.scan.size,
            memory_leaks: Apm::MemoryLeakDetector.scan.size,
            redis: Apm::RedisSaturationDetector.stats,
            pool: Apm::ThreadPoolAnalyzer.stats,
            recent_errors: Storage::RedisStore.read_list("errors", limit: 10)
          }
        end

        def self.render_erb(name, bind)
          path = File.join(ROOT, "views", "#{name}.erb")
          return [404, "Not found"] unless File.exist?(path)
          template = File.read(path)
          erb_result = ERB.new(template).result(bind)
          [200, { "Content-Type" => "text/html" }, [erb_result]]
        end
      end
    end
  end
end
