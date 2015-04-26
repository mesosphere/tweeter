require 'cassandra'
require 'time'

# Oink class that talks to Cassandra
class Analytics
  @@cluster = Cassandra.cluster(
    hosts: ['cassandra-dcos-node.cassandra.dcos.mesos'])
  @@keyspace = 'oinker'
  @@session  = @@cluster.connect(@@keyspace)

  attr_accessor :key, :frequency

  def self.all
    unsorted = @@session.execute(
      'SELECT key, frequency FROM analytics').map do |anal|
      c = Analytics.new
      c.key = anal['key']
      c.frequency = anal['frequency']
      c
    end
    unsorted.sort do |a, b|
      b.frequency <=> a.frequency
    end
  end
end
