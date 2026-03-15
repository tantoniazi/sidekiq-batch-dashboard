# frozen_string_literal: true

# Load APM components (storage, apm, diagnostics) and Web extension.
require "sidekiq/batch/dashboard/storage/redis_store"
require "sidekiq/batch/dashboard/storage/metrics_store"
require "sidekiq/batch/dashboard/apm/worker_profiler"
require "sidekiq/batch/dashboard/apm/memory_leak_detector"
require "sidekiq/batch/dashboard/apm/stuck_job_detector"
require "sidekiq/batch/dashboard/apm/deadlock_detector"
require "sidekiq/batch/dashboard/apm/redis_saturation_detector"
require "sidekiq/batch/dashboard/apm/thread_pool_analyzer"
require "sidekiq/batch/dashboard/diagnostics/concurrency_analyzer"
require "sidekiq/batch/dashboard/diagnostics/thread_safety_checker"
require "sidekiq/batch/dashboard/diagnostics/config_analyzer"
require "sidekiq/batch/dashboard/web_extension"

module Sidekiq
  module Batch
    module Dashboard
      module Web
        def self.use!
          return unless defined?(::Sidekiq::Web)
          if ::Sidekiq::Web.respond_to?(:register) && ::Sidekiq::Web.method(:register).arity != 1
            # Sidekiq 7.3+ API: name, tab, index, root_dir, asset_paths, cache_for
            ::Sidekiq::Web.register(WebExtension,
              name: "apm",
              tab: %w[Dashboard Workers Failures Logs Concurrency Redis Memory Diagnostics],
              index: %w[apm_dashboard apm_workers apm_failures apm_logs apm_concurrency apm_redis apm_memory apm_diagnostics],
              root_dir: WebExtension::ROOT,
              asset_paths: %w[css js],
              cache_for: 86400)
          elsif ::Sidekiq::Web.respond_to?(:register)
            ::Sidekiq::Web.register(WebExtension)
            %w[Dashboard Workers Failures Logs Concurrency Redis Memory Diagnostics].zip(
              %w[apm_dashboard apm_workers apm_failures apm_logs apm_concurrency apm_redis apm_memory apm_diagnostics]
            ).each { |label, path| ::Sidekiq::Web.tabs[label] = path }
          end
          else
            # Fallback for older Sidekiq: add tabs and mount extension
            %w[apm_dashboard apm_workers apm_failures apm_logs apm_concurrency apm_redis apm_memory apm_diagnostics].each { |path| ::Sidekiq::Web.tabs[path.capitalize] = path }
            ::Sidekiq::Web.register(WebExtension)
          end
        end
      end
    end
  end
end

Sidekiq::Batch::Dashboard::Web.use!
