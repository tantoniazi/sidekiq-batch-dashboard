# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Apm
        # Estimates Redis pool usage and latency from Sidekiq's Redis connection.
        class RedisSaturationDetector
          class << self
            def stats
              latency_ms = measure_latency
              info = Sidekiq.redis { |r| r.info("memory") rescue {} }
              used_memory = info["used_memory"]&.to_i
              {
                latency_ms: latency_ms.round(2),
                used_memory_bytes: used_memory,
                used_memory_mb: used_memory ? (used_memory / 1024.0 / 1024.0).round(2) : nil,
                warning: latency_ms > 50 ? "High Redis latency" : nil
              }
            end

            def measure_latency
              start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
              Sidekiq.redis { |r| r.ping }
              (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000
            rescue
              -1
            end
          end
        end
      end
    end
  end
end
