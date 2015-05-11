# Oinks coontroller
class OinksController < ActionController::Base
  layout 'application'

  def create
    Oink.create(oink_params)
    redirect_to root_path
  end

  def destroy
    Oink.find(params[:id]).destroy
    redirect_to root_path
  end

  def index
    @oinks = Oink.all(params[:paged].present?)
  end

  def show
    @oink = Oink.find(params[:id])
  end

  private

  def oink_params
    params.require(:oink).permit(:content, :handle)
  end
end
