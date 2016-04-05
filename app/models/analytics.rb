require 'cassandra'
require 'time'

# Tweet class that talks to Cassandra
class Analytics
  @@cluster = Cassandra.cluster(CASSANDRA_OPTIONS)
  @@keyspace = 'tweeter'
  @@session  = @@cluster.connect(@@keyspace)
  @@paging_state = nil

  attr_accessor :key, :frequency

  def self.all(paged = false)
    results = @@session.execute(
      'SELECT key, frequency FROM analytics ' \
      'WHERE kind = ? ORDER BY frequency DESC',
      arguments: ['tweet'],
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
