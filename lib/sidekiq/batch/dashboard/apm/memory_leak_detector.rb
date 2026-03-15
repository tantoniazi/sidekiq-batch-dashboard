# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Apm
        # Detects workers where memory_after > memory_before consistently (moving average).
        class MemoryLeakDetector
          MIN_SAMPLES = 5
          GROWTH_THRESHOLD_BYTES = 2 * 1024 * 1024  # 2MB average increase

          class << self
            def scan
              metrics = Storage::MetricsStore.recent_metrics(limit: 2000)
              by_worker = metrics.group_by { |m| m[:worker].to_s }
              by_worker.filter_map do |worker, samples|
                next if samples.size < MIN_SAMPLES
                deltas = samples.filter_map { |s| s[:memory_delta] }.compact
                next if deltas.empty?
                avg_delta = deltas.sum.to_f / deltas.size
                next unless avg_delta > GROWTH_THRESHOLD_BYTES
                {
                  worker: worker,
                  sample_count: samples.size,
                  avg_memory_increase_bytes: avg_delta.round(0),
                  avg_memory_increase_mb: (avg_delta / 1024.0 / 1024.0).round(2)
                }
              end
            end
          end
        end
      end
    end
  end
end
