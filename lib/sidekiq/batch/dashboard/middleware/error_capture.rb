# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Middleware
        # Captures job errors (and optionally swallowed errors via logger hook) for APM.
        class ErrorCapture
          def call(worker, job, queue)
            yield
          rescue => e
            self.class.record_error(worker: worker, job: job, queue: queue, error: e, swallowed: false)
            raise
          end

          def self.record_error(worker:, job:, queue:, error:, swallowed: false)
            payload = {
              worker: worker.is_a?(Class) ? worker.name : worker.class.name,
              jid: job["jid"],
              queue: queue,
              error_class: error.class.name,
              error_message: error.message.to_s[0, 1024],
              swallowed: swallowed,
              at: Time.now.to_f
            }
            Storage::RedisStore.push_list("errors", payload, max_size: 5000)
          end
        end
      end
    end
  end
end
