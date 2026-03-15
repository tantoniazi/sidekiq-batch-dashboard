# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Inspects a single batch: status, progress, failure details.
      class BatchInspector
        def initialize(bid)
          @bid = bid
          @status = status_object
        end

        def batch_info
          RedisBatchLoader.find_batch(@bid)
        end

        def completed_count
          return 0 unless @status
          [@status.total - @status.pending, 0].max
        end

        def success_rate
          return 0.0 if !@status || @status.total.zero?
          completed = @status.total - @status.pending
          failed = @status.failures
          success = [completed - failed, 0].max
          (success.to_f / @status.total * 100).round(2)
        end

        def failure_info
          jids = failed_jids
          return [] if jids.blank?
          jids.filter_map { |jid| job_detail(jid) }
        end

        def failed_jids
          RedisAdapter.batch_failed_jids(@bid)
        end

        private

        def status_object
          return nil unless defined?(::Sidekiq::Batch::Status)
          ::Sidekiq::Batch::Status.new(@bid)
        rescue
          nil
        end

        def job_detail(jid)
          # Try to find job in RetrySet or DeadSet for error message
          [Sidekiq::RetrySet.new, Sidekiq::DeadSet.new].each do |set|
            set.each do |job|
              return format_job(job) if job.jid == jid
            end
          end
          { jid: jid, error_message: nil, worker: nil, args: [] }
        end

        def format_job(job)
          {
            jid: job.jid,
            error_message: job.item["error_message"],
            worker: job.respond_to?(:display_class) ? job.display_class : job.item["class"],
            args: job.item["args"] || [],
            retry_count: job.item["retry_count"].to_i
          }
        end
      end
    end
  end
end
