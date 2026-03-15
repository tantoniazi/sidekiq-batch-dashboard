# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Diagnostics
        # Static analysis: detect class variables, mutable constants, unsafe patterns in worker code.
        class ThreadSafetyChecker
          UNSAFE_PATTERNS = [
            { pattern: /@@\w+/, message: "Worker uses class variable (not thread-safe)" },
            { pattern: /\b(\w+)\.memoize\b/, message: "Possible unsafe memoization" },
            { pattern: /\$[a-zA-Z_]\w*\s*=/, message: "Global variable assignment" }
          ].freeze

          class << self
            def scan(worker_classes = nil)
              workers = worker_classes || discover_workers
              workers.filter_map do |klass|
                path = path_for(klass)
                next unless path && File.exist?(path)
                src = File.read(path)
                issues = UNSAFE_PATTERNS.filter_map do |u|
                  u[:message] if src.match?(u[:pattern])
                end
                next if issues.empty?
                { worker: klass.name, path: path, issues: issues }
              end
            end

            def discover_workers
              ObjectSpace.each_object(Class).select do |c|
                c.include?(Sidekiq::Worker) rescue (defined?(Sidekiq::Job) && c.include?(Sidekiq::Job)) rescue false
              end
            end

            def path_for(klass)
              return nil unless klass.name
              path = (klass.name.respond_to?(:underscore) ? klass.name.underscore : klass.name.gsub("::", "/").downcase) + ".rb"
              $LOAD_PATH.each do |base|
                full = File.join(base, path)
                return full if File.exist?(full)
              end
              nil
            end
          end
        end
      end
    end
  end
end
