require File.expand_path('../boot', __FILE__)

# require 'rails/all'

# Include individual models to prevent initializing ActiveRecord
# See: http://stackoverflow.com/a/19078854/368697
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'rails/test_unit/railtie'
require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsOnMesos
  class Application < Rails::Application
  end
end
