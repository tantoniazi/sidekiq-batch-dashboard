# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      class ProgressBarComponent < ViewComponent::Base
        def initialize(current:, total:, label: nil, show_percent: true)
          @current = current.to_i
          @total = total.to_i
          @label = label
          @show_percent = show_percent
        end

        def percent
          return 0 if @total.zero?
          [100, (@current.to_f / @total * 100).round(2)].min
        end
      end
    end
  end
end
