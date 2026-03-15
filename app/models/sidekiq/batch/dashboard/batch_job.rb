# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Value object for a job (from RetrySet, DeadSet, or batch failure set).
      class BatchJob
        attr_reader :jid, :worker_class, :args, :queue, :status, :runtime, :batch_id, :error_message, :retry_count

        def initialize(jid:, worker_class: nil, args: [], queue: nil, status: nil, runtime: nil, batch_id: nil, error_message: nil, retry_count: 0)
          @jid = jid
          @worker_class = worker_class
          @args = args || []
          @queue = queue
          @status = status
          @runtime = runtime
          @batch_id = batch_id
          @error_message = error_message
          @retry_count = retry_count.to_i
        end

        def self.from_sidekiq_job(job)
          item = job.respond_to?(:item) ? job.item : job
          item = item.with_indifferent_access if item.respond_to?(:with_indifferent_access)
          jid = item["jid"] || item[:jid]
          status = dead?(job) ? "dead" : "retry"
          new(
            jid: jid,
            worker_class: item["class"] || item["wrapped"] || item[:class] || item[:wrapped],
            args: item["args"] || item[:args] || [],
            queue: item["queue"] || item[:queue],
            status: status,
            error_message: item["error_message"] || item[:error_message],
            retry_count: (item["retry_count"] || item[:retry_count]).to_i
          )
        end

        def self.dead?(job)
          job.class.name.include?("DeadSet") || (job.respond_to?(:item) && job.item["dead"])
        end
      end
    end
  end
end
