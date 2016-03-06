# Tweets coontroller
class TweetsController < ActionController::Base
  layout 'application'

  def create
    @tweet = Tweet.create(tweet_params)
    log_tweet(@tweet)
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

  def log_tweet(tweet)
    # TODO move producer setup out of request/response cycle
    kafka = Kafka.new(KAFKA_OPTIONS)
    producer = kafka.producer
    producer.produce(tweet.to_json, topic: KAFKA_TOPIC)
    producer.deliver_messages
  end
end
