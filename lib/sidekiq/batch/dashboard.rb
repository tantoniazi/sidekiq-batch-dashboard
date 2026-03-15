require "sidekiq/batch/dashboard/version"
require "sidekiq/batch/dashboard/engine"
require "sidekiq/batch/dashboard/redis_adapter"

module Sidekiq
  module Batch
    module Dashboard
      # Mountable engine for Sidekiq Batch monitoring.
      # Use in host app: mount SidekiqBatchDashboard::Engine => "/batches"
    end
  end
end

# Alias for convenient mounting: mount SidekiqBatchDashboard::Engine => "/batches"
SidekiqBatchDashboard = Sidekiq::Batch::Dashboard
