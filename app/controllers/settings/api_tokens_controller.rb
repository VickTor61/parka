class Settings::ApiTokensController < ApplicationController
  before_action :set_api_token, only: %i[ update destroy ]

  def index
    @q = Current.user.api_tokens.ransack(search_params)
    @q.sorts = "created_at desc" if @q.sorts.empty?

    @pagy, @api_tokens = pagy(@q.result, limit: limit_param)
  end

  def new
    @api_token = Current.user.api_tokens.new
  end

  def create
    @api_token = Current.user.api_tokens.new(api_token_params)

    if @api_token.save
      reveal_once @api_token
      redirect_out_of_frame settings_api_tokens_path, notice: "Token created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @api_token.update!(active: ActiveModel::Type::Boolean.new.cast(params.dig(:api_token, :active)))

    redirect_to settings_api_tokens_path, notice: @api_token.active? ? "Token activated." : "Token deactivated."
  end

  def destroy
    @api_token.destroy

    redirect_to settings_api_tokens_path, notice: "Token deleted."
  end

  private
    def set_api_token
      @api_token = Current.user.api_tokens.find(params[:id])
    end

    def api_token_params
      params.expect(api_token: [ :name ])
    end

    def reveal_once(api_token)
      flash[:revealed_token] = api_token.token
      flash[:revealed_token_name] = api_token.name
    end
end
