# frozen_string_literal: true

module Sidekiq
  module Batch
    module Dashboard
      class StatsCardComponent < ViewComponent::Base
        def initialize(title:, value:, subtitle: nil, badge: nil, css_class: "primary")
          @title = title
          @value = value
          @subtitle = subtitle
          @badge = badge
          @css_class = css_class
        end
      end
    end
  end
end
