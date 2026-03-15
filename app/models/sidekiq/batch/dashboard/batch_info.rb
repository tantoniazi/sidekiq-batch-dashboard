# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Value object for batch metadata from Redis.
      class BatchInfo
        attr_reader :id, :total, :pending, :created_at, :complete, :description, :failed_count, :failed_jids

        def initialize(id:, total: 0, pending: 0, created_at: nil, complete: false, description: nil, failed_count: 0, failed_jids: [])
          @id = id
          @total = total
          @pending = pending
          @created_at = created_at
          @complete = complete
          @description = description
          @failed_count = failed_count || 0
          @failed_jids = failed_jids || []
        end

        def completed_count
          [total - pending, 0].max
        end

        def status
          return "failed" if failed_count.positive? && complete
          return "complete" if complete
          "running"
        end

        def success_rate
          return 0.0 if total.zero?
          success = [completed_count - failed_count, 0].max
          (success.to_f / total * 100).round(2)
        end
      end
    end
  end
end
