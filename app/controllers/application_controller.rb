class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern

  stale_when_importmap_changes

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private
    def record_not_found
      redirect_back fallback_location: root_path, alert: "That record could not be found."
    end
end
