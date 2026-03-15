# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Apm
        # Finds jobs in Redis "running" set that exceed threshold (default 5x average runtime).
        class StuckJobDetector
          KEY_PREFIX = "sidekiq:apm:running"
          MULTIPLIER = 5
          MIN_RUNTIME_SECONDS = 60

          class << self
            def scan
              running = fetch_running_jobs
              return [] if running.empty?
              avg_duration = average_expected_duration
              threshold = [avg_duration * MULTIPLIER, MIN_RUNTIME_SECONDS].max

              running.filter_map do |payload|
                started = payload[:started_at].to_f
                runtime = Time.now.to_f - started
                next if runtime < threshold
                {
                  worker: payload[:worker],
                  jid: payload[:jid],
                  queue: payload[:queue],
                  expected_approx_sec: avg_duration.round(1),
                  running_sec: runtime.round(1),
                  started_at: Time.at(started)
                }
              end
            end

            def fetch_running_jobs
              keys = []
              Sidekiq.redis { |r| r.scan_each(match: "#{KEY_PREFIX}:*", count: 100) { |k| keys << k } }
              return [] if keys.empty?
              raw = Sidekiq.redis { |r| r.mget(keys) }
              raw.filter_map { |s| Storage::RedisStore.deserialize(s) }
            end

            def average_expected_duration
              stats = Storage::MetricsStore.worker_stats(window_seconds: 3600)
              durs = stats.values.filter_map { |s| s[:avg_duration] }
              durs.empty? ? MIN_RUNTIME_SECONDS.to_f : (durs.sum / durs.size.to_f)
            end
          end
        end
      end
    end
  end
end
