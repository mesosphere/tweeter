require 'cassandra'
require 'time'

# Tweet class that talks to Cassandra
class Tweet
  include ActiveModel::Serialization

  @@cluster = Cassandra.cluster(CASSANDRA_OPTIONS)
  @@keyspace = 'tweeter'
  @@session  = @@cluster.connect(@@keyspace)
  @@generator = Cassandra::Uuid::Generator.new
  @@paging_state = nil

  attr_accessor :id, :content, :created_at, :handle

  def avatar_url
    "//robohash.org/#{handle}.png?size=144x144&amp;bgset=bg2"
  end

  def attributes
    {'id' => id, 'content' => content, 'created_at' => created_at, 'handle' => handle}
  end

  def destroy
    @@session.execute(
      'DELETE from tweets WHERE id = ?',
      arguments: [@id])
  end

  def self.all(paged = false)
    result = @@session.execute(
      'SELECT id, content, created_at, handle FROM tweets ' \
      'WHERE kind = ? ORDER BY created_at DESC',
      arguments: ['tweet'],
      page_size: 25,
      paging_state: (paged ? @@paging_state : nil)
    )
    @@paging_state = result.paging_state
    result.map do |tweet|
      c = Tweet.new
      c.id, c.content, c.handle = tweet['id'], tweet['content'], tweet['handle']
      c.created_at = tweet['created_at'].to_time.utc.iso8601
      c
    end
  end

  def self.create(params)
    c = Tweet.new
    c.id = SecureRandom.urlsafe_base64
    c.content = params[:content]
    cassandra_time = @@generator.now
    c.created_at = cassandra_time.to_time.utc.iso8601
    c.handle = params[:handle].downcase
    @@session.execute(
      'INSERT INTO tweets (kind, id, content, created_at, handle) ' \
      'VALUES (?, ?, ?, ?, ?)',
      arguments: ['tweet', c.id, c.content, cassandra_time, c.handle])
    c
  end

  def self.find(id)
    tweet = @@session.execute(
      'SELECT id, content, created_at, handle FROM tweets WHERE id = ?',
      arguments: [id]).first
    c = Tweet.new
    c.id = tweet['id']
    c.content = tweet['content']
    c.created_at = tweet['created_at'].to_time.utc.iso8601
    c.handle = tweet['handle']
    c
  end
end
