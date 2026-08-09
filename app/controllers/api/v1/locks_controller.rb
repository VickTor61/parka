class Api::V1::LocksController < Api::V1::BaseController
  def index
    scope = current_user.period_locks.ransack(search_params).result.ordered
    records, meta = paginated(scope)

    render_collection records, meta, PeriodLockBlueprint
  end

  def show
    render_resource current_user.period_locks.find(params[:id]), PeriodLockBlueprint
  end

  def create
    period_lock = current_user.period_locks.new(lock_params)

    if period_lock.save
      render_resource period_lock, PeriodLockBlueprint, status: :created
    else
      render_errors period_lock
    end
  end

  def destroy
    current_user.period_locks.find(params[:id]).destroy

    head :no_content
  end

  private
    def lock_params
      params.expect(period_lock: [ :month ])
    end
end
