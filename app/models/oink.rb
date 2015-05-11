require 'cassandra'
require 'time'

# Oink class that talks to Cassandra
class Oink
  @@cluster = Cassandra.cluster(
    hosts: ['cassandra-dcos-node.cassandra.dcos.mesos'])
  @@keyspace = 'oinker'
  @@session  = @@cluster.connect(@@keyspace)
  @@generator = Cassandra::Uuid::Generator.new
  @@paging_state = nil

  attr_accessor :id, :content, :created_at, :handle

  attr_writer :content, :created_at, :handle

  def avatar_url
    "//robohash.org/#{handle}.png?size=144x144&amp;bgset=bg2"
  end

  def destroy
    @@session.execute(
      'DELETE from oinks WHERE id = ?',
      arguments: [@id])
  end

  def self.all(paged = false)
    result = @@session.execute(
      'SELECT id, content, created_at, handle FROM oinks ' \
      'WHERE kind = ? ORDER BY created_at DESC',
      arguments: ['oink'],
      page_size: 25,
      paging_state: (paged ? @@paging_state : nil)
    )
    @@paging_state = result.paging_state
    result.map do |oink|
      c = Oink.new
      c.id, c.content, c.handle = oink['id'], oink['content'], oink['handle']
      c.created_at = oink['created_at'].to_time.utc.iso8601
      c
    end
  end

  def self.create(params)
    c = Oink.new
    c.id = SecureRandom.urlsafe_base64
    c.content = params[:content]
    cassandra_time = @@generator.now
    c.created_at = cassandra_time.to_time.utc.iso8601
    c.handle = params[:handle].downcase
    @@session.execute(
      'INSERT INTO oinks (kind, id, content, created_at, handle) ' \
      'VALUES (?, ?, ?, ?, ?)',
      arguments: ['oink', c.id, c.content, cassandra_time, c.handle])
    c
  end

  def self.find(id)
    oink = @@session.execute(
      'SELECT id, content, created_at, handle FROM oinks WHERE id = ?',
      arguments: [id]).first
    c = Oink.new
    c.id = oink['id']
    c.content = oink['content']
    c.created_at = oink['created_at'].to_time.utc.iso8601
    c.handle = oink['handle']
    c
  end
end
