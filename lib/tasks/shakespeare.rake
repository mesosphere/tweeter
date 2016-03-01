namespace :shakespeare do
  desc "Post Tweets from a file"
  task :tweet => :environment do
    filename = ARGV[1]
    uri = URI.parse(ARGV[2])
    http = Net::HTTP.new(uri.host, uri.port)
    request_headers = {
      'Content-Type' => 'application/json'
    }

    File.foreach(filename) do |line|
      begin
        data = ActiveSupport::JSON.decode(line)
        tweet = {
          handle: data['speaker'],
          content: data['text_entry']
        }
        body = ActiveSupport::JSON.encode(tweet)
        http.request_post('/tweets', body, request_headers)
        puts tweet
      rescue JSON::ParserError => e
        Rails.logger.error(e)
      end
    end
  end
end
