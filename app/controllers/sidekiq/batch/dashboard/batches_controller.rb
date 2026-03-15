# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      class BatchesController < ApplicationController
        def index
          @batches = RedisBatchLoader.list_batches(count: 500)
          @batches = apply_filter(@batches)
          @batches = apply_sort(@batches)
        end

        def show
          @batch_info = RedisBatchLoader.find_batch(params[:id])
          unless @batch_info
            redirect_to root_path, alert: "Batch not found" and return
          end
          @inspector = BatchInspector.new(params[:id])
        end

        private

        def apply_sort(batches)
          case params[:sort]
          when "created_at_asc"
            batches.sort_by { |b| b.created_at || Time.at(0) }
          when "total_desc"
            batches.sort_by { |b| -b.total }
          when "failed_desc"
            batches.sort_by { |b| -b.failed_count }
          when "status"
            batches.sort_by { |b| [b.status == "running" ? 0 : 1, -(b.created_at&.to_i || 0)] }
          else
            batches.sort_by { |b| -(b.created_at&.to_i || 0) }
          end
        end

        def apply_filter(batches)
          case params[:status]
          when "running"
            batches.select { |b| b.status == "running" }
          when "complete"
            batches.select { |b| b.status == "complete" }
          when "failed"
            batches.select { |b| b.status == "failed" }
          else
            batches
          end
        end
      end
    end
  end
end
