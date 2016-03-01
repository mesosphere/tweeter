# Cassandra config
CASSANDRA_OPTIONS = if Rails.env.production?
  {
    hosts: ['cassandra-dcos-node.cassandra.dcos.mesos']
  }
else
  {
    hosts: ['127.0.0.1']
  }
end
