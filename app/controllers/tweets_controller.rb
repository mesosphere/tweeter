# Tweets coontroller
class TweetsController < ActionController::Base
  layout 'application'

  def create
    Tweet.create(tweet_params)
    redirect_to root_path
  end

  def destroy
    Tweet.find(params[:id]).destroy
    redirect_to root_path
  end

  def index
    @tweets = Tweet.all(params[:paged].present?)
  end

  def show
    @tweet = Tweet.find(params[:id])
  end

  private

  def tweet_params
    params.require(:tweet).permit(:content, :handle)
  end
end
