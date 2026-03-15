# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Wraps Sidekiq's Redis connection for batch key access.
      # sidekiq-batch uses: BID-{bid} (hash), BID-{bid}-failed (set).
      class RedisAdapter
        BATCH_KEY_PREFIX = "BID-"
        BATCH_KEY_FAILED_SUFFIX = "-failed"

        class << self
          def redis
            Sidekiq.redis { |conn| yield conn }
          end

          # Scan Redis for all batch IDs (keys matching BID-* but not BID-*-failed).
          def batch_ids(cursor: "0", count: 100)
            batch_ids = []
            cursor = cursor.to_s
            loop do
              cursor, keys = redis { |r| r.scan(cursor, match: "#{BATCH_KEY_PREFIX}*", count: count) }
              keys.each do |key|
                next if key.end_with?(BATCH_KEY_FAILED_SUFFIX)
                bid = key.delete_prefix(BATCH_KEY_PREFIX)
                batch_ids << bid
              end
              break if cursor == "0"
            end
            batch_ids.uniq
          end

          def batch_metadata(bid)
            key = "#{BATCH_KEY_PREFIX}#{bid}"
            redis do |r|
              fields = r.hgetall(key)
              next nil if fields.blank?
              {
                total: fields["total"].to_i,
                pending: fields["pending"].to_i,
                created_at: fields["created_at"],
                complete: fields["complete"] == "true",
                description: fields["description"].presence
              }
            end
          end

          def batch_failed_jids(bid)
            key = "#{BATCH_KEY_PREFIX}#{bid}#{BATCH_KEY_FAILED_SUFFIX}"
            redis { |r| r.smembers(key) || [] }
          end
        end
      end
    end
  end
end
