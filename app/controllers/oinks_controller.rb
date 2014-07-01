class OinksController < ActionController::Base

  layout "application"

  def create
    Oink.create(oink_params)
    redirect_to root_path
  end

  def destroy
    Oink.find(params[:id]).destroy
    redirect_to root_path
  end

  def index
    @oinks = Oink.all
  end

  def show
    # Use existence of `created_at` as a proxy for existence
    unless Oink.all.include?(params[:id])
      raise ActionController::RoutingError.new('Not Found')
    end

    @oink = Oink.find(params[:id])
  end

  private

    def oink_params
      params.require(:oink).permit(:content, :handle)
    end

end
