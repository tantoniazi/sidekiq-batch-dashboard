# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Diagnostics
        # Analyzes concurrency bottlenecks from queue sizes and worker throughput.
        class ConcurrencyAnalyzer
          class << self
            def run
              pool = Apm::ThreadPoolAnalyzer.stats
              redis = Apm::RedisSaturationDetector.stats
              issues = []
              issues << "Thread pool saturated (concurrency #{pool[:concurrency]}, backlog #{pool[:queue_backlog]})" if pool[:saturated]
              issues << "High Redis latency: #{redis[:latency_ms]}ms" if redis[:latency_ms] > 50 && redis[:latency_ms] >= 0
              { issues: issues, pool: pool, redis: redis }
            end
          end
        end
      end
    end
  end
end
