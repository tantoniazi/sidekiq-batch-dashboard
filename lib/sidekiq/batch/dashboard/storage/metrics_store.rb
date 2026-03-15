# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Storage
        # Batched, sampled metrics storage with TTL. Low Redis overhead.
        class MetricsStore
          BATCH_KEY = "sidekiq:apm:metrics:batch"
          FLUSH_INTERVAL = 5
          SAMPLE_RATE = 1.0  # 1.0 = 100%, 0.1 = 10%
          TTL = 86400 * 2   # 2 days
          MAX_ITEMS_PER_FLUSH = 100

          class << self
            def record(payload)
              return unless rand < SAMPLE_RATE
              payload = payload.slice(
                :worker, :jid, :queue, :started_at, :ended_at, :duration,
                :memory_before, :memory_after, :memory_delta, :thread_id,
                :retry_count, :batch_id, :error_class
              ).compact
              payload[:started_at] = payload[:started_at].to_f if payload[:started_at]
              payload[:ended_at] = payload[:ended_at].to_f if payload[:ended_at]
              buffer << payload
              flush_if_needed
            end

            def buffer
              Thread.current[:sidekiq_apm_metrics_buffer] ||= []
            end

            def flush_if_needed
              return if buffer.size < MAX_ITEMS_PER_FLUSH
              flush
            end

            def flush
              items = buffer.shift(buffer.size)
              return if items.empty?
              key_base = "sidekiq:apm:job_metrics"
              Sidekiq.redis do |r|
                r.pipelined do |pipe|
                  items.each_with_index do |item, i|
                    k = "#{key_base}:#{Time.now.to_i}:#{i}"
                    pipe.setex(k, TTL, RedisStore.serialize(item))
                  end
                end
              end
            end

            def recent_metrics(limit: 500)
              pattern = "sidekiq:apm:job_metrics:*"
              keys = []
              Sidekiq.redis do |r|
                r.scan_each(match: pattern, count: 1000) { |k| keys << k }
              end
              keys = keys.sort_by { |k| k.split(":").last(2).join(":").to_i }.last(limit)
              return [] if keys.empty?
              raw = Sidekiq.redis { |r| r.mget(keys) }
              raw.filter_map { |s| RedisStore.deserialize(s) }
            end

            def worker_stats(window_seconds: 3600)
              metrics = recent_metrics(limit: 5000)
              cutoff = Time.now.to_f - window_seconds
              metrics = metrics.select { |m| (m[:ended_at] || m[:started_at]).to_f > cutoff }
              by_worker = metrics.group_by { |m| m[:worker].to_s }
              by_worker.transform_values do |vals|
                durs = vals.filter_map { |v| v[:duration] }.compact
                mem_deltas = vals.filter_map { |v| v[:memory_delta] }.compact
                {
                  count: vals.size,
                  avg_duration: durs.empty? ? nil : (durs.sum / durs.size.to_f).round(3),
                  max_duration: durs.max,
                  avg_memory_delta: mem_deltas.empty? ? nil : (mem_deltas.sum / mem_deltas.size.to_f).round(0),
                  samples: vals.size
                }
              end
            end
          end
        end
      end
    end
  end
end
