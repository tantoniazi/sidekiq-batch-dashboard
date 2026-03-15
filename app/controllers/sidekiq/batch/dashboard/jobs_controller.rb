# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      class JobsController < ApplicationController
        def index
          @jobs = load_batch_jobs
          @batch_id = params[:batch_id]
        end

        private

        def load_batch_jobs
          jobs = []
          if params[:batch_id].present?
            jids = RedisAdapter.batch_failed_jids(params[:batch_id])
            jids.each { |jid| jobs << fetch_job_by_jid(jid, params[:batch_id]) }
          else
            # All failed/retry jobs (limit for display)
            limit = 500
            Sidekiq::RetrySet.new.each { |job| jobs << BatchJob.from_sidekiq_job(job); break if jobs.size >= limit }
            Sidekiq::DeadSet.new.each { |job| jobs << BatchJob.from_sidekiq_job(job); break if jobs.size >= limit } if jobs.size < limit
          end
          jobs.compact
        end

        def fetch_job_by_jid(jid, batch_id = nil)
          [Sidekiq::RetrySet.new, Sidekiq::DeadSet.new].each do |set|
            set.each do |job|
              job_jid = job.respond_to?(:item) ? job.item["jid"] : (job.respond_to?(:jid) ? job.jid : nil)
              next unless job_jid == jid
              bj = BatchJob.from_sidekiq_job(job)
              if batch_id
                bj = BatchJob.new(
                  jid: bj.jid,
                  worker_class: bj.worker_class,
                  args: bj.args,
                  queue: bj.queue,
                  status: bj.status,
                  runtime: bj.runtime,
                  batch_id: batch_id,
                  error_message: bj.error_message,
                  retry_count: bj.retry_count
                )
              end
              return bj
            end
          end
          BatchJob.new(jid: jid, batch_id: batch_id, status: "unknown")
        end
      end
    end
  end
end
