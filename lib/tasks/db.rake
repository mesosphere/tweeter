require 'cassandra'

namespace :cassandra do
  desc "TODO"
  task :setup => :environment do
  	cluster = Cassandra.cluster(CASSANDRA_OPTIONS)
    keyspace = 'tweeter'
    session  = cluster.connect()
    session.execute(
      "CREATE KEYSPACE IF NOT EXISTS tweeter WITH replication = \
      {'class': 'SimpleStrategy','replication_factor': 3}")
    session.execute(
      "CREATE TABLE IF NOT EXISTS tweeter.tweets ( \
          kind VARCHAR, \
          id VARCHAR, \
          content VARCHAR, \
          created_at timeuuid, \
          handle VARCHAR, \
          PRIMARY KEY (kind, created_at) \
      ) WITH CLUSTERING ORDER BY (created_at DESC)"
    )
    session.execute(
      "CREATE TABLE IF NOT EXISTS tweeter.analytics ( \
          kind VARCHAR, \
          key VARCHAR, \
          frequency INT, \
          PRIMARY KEY (kind, frequency) \
      ) WITH CLUSTERING ORDER BY (frequency DESC)"
    )
  end
end
