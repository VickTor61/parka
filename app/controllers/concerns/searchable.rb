module Searchable
  extend ActiveSupport::Concern

  private
    def search_params
      params[:q]&.permit!&.to_h || {}
    end

    def limit_param
      (params[:limit].presence || 20).to_i.clamp(10, 100)
    end
end
