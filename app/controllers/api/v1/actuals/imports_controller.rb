class Api::V1::Actuals::ImportsController < Api::V1::BaseController
  def create
    import = ActualsImport.new(user: current_user, file: params.dig(:actuals_import, :file) || params[:file])

    if import.save
      render json: { data: { imported_count: import.imported_count } }, status: :created
    else
      render_errors import
    end
  end
end
