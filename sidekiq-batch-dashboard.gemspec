require_relative "lib/sidekiq/batch/dashboard/version"

Gem::Specification.new do |spec|
  spec.name        = "sidekiq-batch-dashboard"
  spec.version     = Sidekiq::Batch::Dashboard::VERSION
  spec.authors     = [ "TODO: Write your name" ]
  spec.email       = [ "TODO: Write your email address" ]
  spec.homepage    = "TODO"
  spec.summary     = "Sidekiq Batch UI + APM (observability inside Sidekiq Web)"
  spec.description = "Mountable Rails Engine for Sidekiq Batch monitoring; plus full APM (concurrency, Redis, memory, stuck jobs, deadlocks, diagnostics) embedded in Sidekiq Web UI."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tantoniazi/sidekiq-batch-dashboard"
  spec.metadata["changelog_uri"] = "https://github.com/tantoniazi/sidekiq-batch-dashboard/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,web}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "sidekiq", ">= 6.0"
  spec.add_dependency "sidekiq-batch", ">= 0.1.0"
  spec.add_dependency "redis", ">= 4.0"
  spec.add_dependency "view_component", ">= 2.0"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "rubocop-rails-omakase", ">= 1.0"
end
