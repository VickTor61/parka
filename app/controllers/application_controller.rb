class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend
  include Searchable

  allow_browser versions: :modern

  stale_when_importmap_changes

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from Pagy::OverflowError, with: :page_out_of_range

  private
    def redirect_out_of_frame(url, notice:)
      respond_to do |format|
        format.turbo_stream do
          flash[:notice] = notice
          render turbo_stream: turbo_stream.action(:redirect, url)
        end

        format.html { redirect_to url, notice: notice }
      end
    end

    def record_not_found
      redirect_back fallback_location: root_path, alert: "That record could not be found."
    end

    def page_out_of_range
      redirect_to url_for(request.params.except("page").merge(only_path: true)), alert: "That page does not exist."
    end
end
