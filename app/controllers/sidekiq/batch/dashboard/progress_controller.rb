# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      class ProgressController < ApplicationController
        def index
          @stats = BatchStatistics.stats_for_progress
          @jobs_per_minute = BatchStatistics.jobs_processed_per_minute(buckets: 24)
        end
      end
    end
  end
end
