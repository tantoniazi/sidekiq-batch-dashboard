# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Fetches batch metadata and job data from Redis (sidekiq-batch keys).
      class RedisBatchLoader
        def self.list_batches(cursor: "0", count: 100)
          bids = RedisAdapter.batch_ids(cursor: cursor, count: count)
          bids.filter_map do |bid|
            meta = RedisAdapter.batch_metadata(bid)
            next nil unless meta
            BatchInfo.new(
              id: bid,
              total: meta[:total],
              pending: meta[:pending],
              created_at: parse_created_at(meta[:created_at]),
              complete: meta[:complete],
              description: meta[:description],
              failed_count: failure_count_for(bid)
            )
          end
        end

        def self.find_batch(bid)
          meta = RedisAdapter.batch_metadata(bid)
          return nil unless meta
          BatchInfo.new(
            id: bid,
            total: meta[:total],
            pending: meta[:pending],
            created_at: parse_created_at(meta[:created_at]),
            complete: meta[:complete],
            description: meta[:description],
            failed_count: failure_count_for(bid),
            failed_jids: RedisAdapter.batch_failed_jids(bid)
          )
        end

        def self.failure_count_for(bid)
          RedisAdapter.batch_failed_jids(bid).size
        end

        def self.parse_created_at(value)
          return nil if value.blank?
          return value if value.is_a?(Time)
          Float(value).then { |f| Time.at(f) } rescue Time.parse(value.to_s)
        end
      end
    end
  end
end
