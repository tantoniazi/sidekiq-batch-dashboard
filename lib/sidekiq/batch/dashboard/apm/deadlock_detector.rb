# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Apm
        # Heuristics: thread running very long, no recent Redis/DB activity (we approximate via running set).
        class DeadlockDetector
          RUNTIME_THRESHOLD_SEC = 120

          class << self
            def scan
              running = StuckJobDetector.fetch_running_jobs
              now = Time.now.to_f
              running.filter_map do |payload|
                started = payload[:started_at].to_f
                runtime = now - started
                next if runtime < RUNTIME_THRESHOLD_SEC
                {
                  worker: payload[:worker],
                  jid: payload[:jid],
                  thread_id: payload[:thread_id],
                  runtime_sec: runtime.round(1),
                  message: "Possible deadlock: running > #{RUNTIME_THRESHOLD_SEC}s"
                }
              end
            end
          end
        end
      end
    end
  end
end
