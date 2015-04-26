# Analytics coontroller
class AnalyticsController < ActionController::Base
  layout 'application'

  def index
    @analytics = Analytics.all
  end
end
