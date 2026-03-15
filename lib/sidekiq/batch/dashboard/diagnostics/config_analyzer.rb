# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Diagnostics
        # Checks Sidekiq and Redis config for common issues.
        class ConfigAnalyzer
          class << self
            def run
              issues = []
              opts = Sidekiq.options

              if opts[:concurrency].to_i > 50
                issues << "High concurrency (#{opts[:concurrency]}) may cause DB pool exhaustion"
              end

              pool = opts[:connection_pool] || opts[:pool]
              if pool && pool.size < (opts[:concurrency] || 10)
                issues << "Redis pool size (#{pool.size}) may be too small for concurrency"
              end

              { issues: issues, concurrency: opts[:concurrency], pool_size: pool&.size }
            end
          end
        end
      end
    end
  end
end
