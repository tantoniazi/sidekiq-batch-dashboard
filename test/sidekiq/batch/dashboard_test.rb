require "test_helper"

class Sidekiq::Batch::DashboardTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Sidekiq::Batch::Dashboard::VERSION
  end
end
