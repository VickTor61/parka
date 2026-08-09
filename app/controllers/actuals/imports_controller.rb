class Actuals::ImportsController < ApplicationController
  def new
    @import = ActualsImport.new(user: Current.user)
  end

  def create
    @import = ActualsImport.new(user: Current.user, file: params.dig(:actuals_import, :file))

    if @import.save
      redirect_out_of_frame actuals_path, notice: "Imported #{helpers.pluralize(@import.imported_count, 'entry')}."
    else
      render :new, status: :unprocessable_content
    end
  end
end
