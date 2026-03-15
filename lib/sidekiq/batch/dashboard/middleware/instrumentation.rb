# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      module Middleware
        # Server middleware: records job start/end, duration, memory delta, queue, jid, batch_id.
        class Instrumentation
          def call(worker, job, queue)
            start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            mem_before = current_memory
            thread_id = Thread.current.object_id

            yield
          ensure
            mem_after = current_memory
            duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
            Storage::MetricsStore.record(
              worker: worker.class.name,
              jid: job["jid"],
              queue: queue,
              started_at: start_time,
              ended_at: Process.clock_gettime(Process::CLOCK_MONOTONIC),
              duration: duration.round(3),
              memory_before: mem_before,
              memory_after: mem_after,
              memory_delta: (mem_after - mem_before).round(0),
              thread_id: thread_id,
              retry_count: job["retry_count"].to_i,
              batch_id: job["bid"]
            )
          end

          private

          def current_memory
            return 0 unless File.exist?("/proc/self/status")
            File.foreach("/proc/self/status") { |line|
              return line.split(/\s+/)[1].to_i * 1024 if line.start_with?("VmRSS:")
            }
            0
          rescue
            0
          end
        end
      end
    end
  end
end
