# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Aggregates statistics across batches for the progress/dashboard charts.
      class BatchStatistics
        def self.recent_batches(limit: 50)
          RedisBatchLoader.list_batches(count: 500).sort_by { |b| b.created_at || Time.at(0) }.reverse.first(limit)
        end

        def self.stats_for_progress
          batches = recent_batches(limit: 100)
          total_jobs = batches.sum(&:total)
          total_failed = batches.sum(&:failed_count)
          completed = batches.sum { |b| b.total - b.pending }
          BatchStat.new(
            total_batches: batches.size,
            total_jobs: total_jobs,
            completed_jobs: completed,
            failed_jobs: total_failed,
            success_rate: total_jobs.positive? ? ((completed - total_failed).to_f / total_jobs * 100).round(2) : 0,
            batches: batches
          )
        end

        # Jobs per minute buckets (last 24 hours) for Chart.js.
        def self.jobs_processed_per_minute(buckets: 24 * 60)
          # Approximate: use batch created_at and completion; without timestamps per job we aggregate by batch.
          batches = recent_batches(limit: 200)
          now = Time.current
          window = 24.hours
          step = window / buckets
          counts = Array.new(buckets, 0)
          batches.each do |b|
            created = b.created_at || now
            next if created < (now - window)
            # Spread completed jobs across a simple decay (assume jobs complete over 5 min for display)
            completed = b.total - b.pending
            idx = [(created.to_i - (now - window).to_i) / step.to_i, 0].max
            idx = [idx, buckets - 1].min
            counts[idx] += completed
          end
          counts
        end
      end
    end
  end
end
