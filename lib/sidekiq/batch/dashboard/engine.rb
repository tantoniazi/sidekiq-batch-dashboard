module Sidekiq
  module Batch
    module Dashboard
      class Engine < ::Rails::Engine
        isolate_namespace Sidekiq::Batch::Dashboard

        config.generators do |g|
          g.test_framework :rspec
        end

        initializer "sidekiq_batch_dashboard.view_components" do |app|
          if defined?(ViewComponent)
            ViewComponent::Base.view_paths << Engine.root.join("app/components")
          end
        end
      end
    end
  end
end
