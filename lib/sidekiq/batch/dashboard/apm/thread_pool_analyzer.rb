# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Apm
        # Compares concurrency vs active threads; flags when all threads busy and queue growing.
        class ThreadPoolAnalyzer
          class << self
            def stats
              # Sidekiq doesn't expose "active thread count" directly; we use running job count as proxy.
              running_count = StuckJobDetector.fetch_running_jobs.size
              config = Sidekiq.options
              concurrency = config[:concurrency] || 10
              queue_sizes = queue_backlog
              total_backlog = queue_sizes.values.sum
              saturated = (running_count >= concurrency) && (total_backlog > 0)

              {
                concurrency: concurrency,
                active_approx: running_count,
                idle_approx: [0, concurrency - running_count].max,
                queue_backlog: total_backlog,
                queue_breakdown: queue_sizes,
                saturated: saturated,
                message: saturated ? "Thread pool saturated; queue backlog increasing" : nil
              }
            end

            def queue_backlog
              Sidekiq.redis do |r|
                queues = r.smembers("queues") || []
                queues.to_h { |q| [q, r.llen("queue:#{q}")] }
              end
            rescue
              {}
            end
          end
        end
      end
    end
  end
end
