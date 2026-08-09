class Settings::ApiTokens::RotationsController < ApplicationController
  def create
    api_token = Current.user.api_tokens.find(params[:api_token_id])
    api_token.rotate!

    flash[:revealed_token] = api_token.token
    flash[:revealed_token_name] = api_token.name

    redirect_to settings_api_tokens_path, notice: "Token rotated — the previous value no longer works."
  end
end
