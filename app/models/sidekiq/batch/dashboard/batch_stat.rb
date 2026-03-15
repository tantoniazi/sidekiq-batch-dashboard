# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      # Value object for aggregated batch statistics (progress page).
      class BatchStat
        attr_reader :total_batches, :total_jobs, :completed_jobs, :failed_jobs, :success_rate, :batches

        def initialize(total_batches: 0, total_jobs: 0, completed_jobs: 0, failed_jobs: 0, success_rate: 0, batches: [])
          @total_batches = total_batches
          @total_jobs = total_jobs
          @completed_jobs = completed_jobs
          @failed_jobs = failed_jobs
          @success_rate = success_rate
          @batches = batches || []
        end

        def pending_jobs
          [total_jobs - completed_jobs, 0].max
        end
      end
    end
  end
end
