# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      class FailuresController < ApplicationController
        def index
          @failures = load_failures
        end

        def retry
          jid = params[:jid]
          job = find_job_in_sets(jid)
          if job&.respond_to?(:retry)
            job.retry
            redirect_to failures_path, notice: "Job #{jid} queued for retry."
          else
            redirect_to failures_path, alert: "Job #{jid} not found in retry or dead set."
          end
        end

        private

        def load_failures
          failures = []
          limit = 500
          Sidekiq::RetrySet.new.each { |job| failures << BatchJob.from_sidekiq_job(job); break if failures.size >= limit }
          Sidekiq::DeadSet.new.each { |job| failures << BatchJob.from_sidekiq_job(job); break if failures.size >= limit } if failures.size < limit
          failures
        end

        def find_job_in_sets(jid)
          Sidekiq::RetrySet.new.each { |job| return job if job.jid == jid }
          Sidekiq::DeadSet.new.each { |job| return job if job.jid == jid }
          nil
        end
      end
    end
  end
end
