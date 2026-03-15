# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Middleware
        # Tracks job start time in Redis so stuck-job detector can find long-running jobs.
        class RuntimeMonitor
          KEY_PREFIX = "sidekiq:apm:running"
          TTL = 86400 * 2  # 2 days

          def call(worker, job, queue)
            jid = job["jid"]
            key = "#{KEY_PREFIX}:#{jid}"
            payload = {
              worker: worker.class.name,
              jid: jid,
              queue: queue,
              started_at: Time.now.to_f,
              thread_id: Thread.current.object_id
            }
            Sidekiq.redis { |r| r.setex(key, TTL, Storage::RedisStore.serialize(payload)) }
            yield
          ensure
            Sidekiq.redis { |r| r.del(key) }
          end
        end
      end
    end
  end
end
