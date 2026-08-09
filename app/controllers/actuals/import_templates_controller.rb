class Actuals::ImportTemplatesController < ApplicationController
  def show
    send_data ActualsImport.template_csv, filename: "parka-actuals-template.csv", type: "text/csv"
  end
end
