# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      class ChartComponent < ViewComponent::Base
        def initialize(id:, type: "line", labels: [], datasets: [], height: 300)
          @id = id
          @type = type
          @labels = labels
          @datasets = datasets
          @height = height
        end
      end
    end
  end
end
