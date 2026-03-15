# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Storage
        # Redis-backed store for APM data with TTL, batched writes, and size limits.
        class RedisStore
          NAMESPACE = "sidekiq:apm"
          DEFAULT_TTL = 86400 * 7  # 7 days
          MAX_PAYLOAD_BYTES = 4 * 1024  # 4KB per job payload
          MAX_ARGS_DISPLAY = 500  # chars for sanitized args in UI

          class << self
            def redis
              Sidekiq.redis { |c| yield c }
            end

            def key(*parts)
              [NAMESPACE, *parts].join(":")
            end

            def write(key_suffix, data, ttl: DEFAULT_TTL)
              k = key(key_suffix)
              redis do |r|
                r.multi do |tx|
                  tx.setex(k, ttl, serialize(data))
                end
              end
            end

            def read(key_suffix)
              k = key(key_suffix)
              raw = redis { |r| r.get(k) }
              raw ? deserialize(raw) : nil
            end

            def push_list(list_suffix, item, max_size: 10_000, ttl: DEFAULT_TTL)
              list_key = key(list_suffix)
              redis do |r|
                r.multi do |tx|
                  tx.lpush(list_key, serialize(item))
                  tx.ltrim(list_key, 0, max_size - 1)
                  tx.expire(list_key, ttl)
                end
              end
            end

            def read_list(list_suffix, limit: 100)
              list_key = key(list_suffix)
              items = redis { |r| r.lrange(list_key, 0, limit - 1) }
              items.map { |raw| deserialize(raw) }.compact
            end

            def increment(counter_suffix, ttl: DEFAULT_TTL)
              k = key(counter_suffix)
              redis do |r|
                r.multi do |tx|
                  n = tx.incr(k)
                  tx.expire(k, ttl) if ttl
                  n
                end
              end
            end

            def serialize(obj)
              JSON.generate(obj)
            end

            def deserialize(str)
              JSON.parse(str, symbolize_names: true)
            rescue
              nil
            end

            def sanitize_args(args)
              return "[redacted]" if args.nil?
              str = args.is_a?(String) ? args : args.to_json
              str = str[0, MAX_ARGS_DISPLAY] + "…" if str.bytesize > MAX_ARGS_DISPLAY
              str.bytesize > MAX_PAYLOAD_BYTES ? str[0, MAX_PAYLOAD_BYTES] + "…" : str
            end
          end
        end
      end
    end
  end
end
