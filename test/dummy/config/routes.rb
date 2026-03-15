Rails.application.routes.draw do
  mount SidekiqBatchDashboard::Engine => "/batches"
end
