require 'cassandra'
require 'time'

# Oink class that talks to Cassandra
class Analytics
  @@cluster = Cassandra.cluster(
    hosts: ['cassandra-dcos-node.cassandra.dcos.mesos'])
  @@keyspace = 'oinker'
  @@session  = @@cluster.connect(@@keyspace)
  @@paging_state = nil

  attr_accessor :key, :frequency

  def self.all(paged = false)
    results = @@session.execute(
      'SELECT key, frequency FROM analytics ' \
      'WHERE kind = ? ORDER BY frequency DESC',
      arguments: ['oink'],
      page_size: 25,
      paging_state: (paged ? @@paging_state : nil)
    )
    @@paging_state = results.paging_state
    results.map do |anal|
      c = Analytics.new
      c.key, c.frequency = anal['key'], anal['frequency']
      c
    end
  end
end
