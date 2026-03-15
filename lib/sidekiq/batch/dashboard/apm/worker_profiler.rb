# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Apm
        # Aggregates per-worker duration, throughput, and percentiles from MetricsStore.
        class WorkerProfiler
          def self.top_slow_workers(limit: 20, window_seconds: 3600)
            stats = Storage::MetricsStore.worker_stats(window_seconds: window_seconds)
            stats.map { |worker, s| s.merge(worker: worker) }
                 .sort_by { |s| -(s[:max_duration] || 0) }
                 .first(limit)
          end

          def self.throughput_by_queue(window_seconds: 3600)
            metrics = Storage::MetricsStore.recent_metrics(limit: 5000)
            cutoff = Time.now.to_f - window_seconds
            metrics = metrics.select { |m| (m[:ended_at] || m[:started_at]).to_f > cutoff }
            metrics.group_by { |m| m[:queue].to_s }.transform_values(&:size)
          end
        end
      end
    end
  end
end
