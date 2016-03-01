# Kafka config
KAFKA_OPTIONS = if Rails.env.production?
  {
    seed_brokers: ['broker-0.kafka.mesos:9092'],
    logger: Rails.logger
  }
else
  {
    seed_brokers: ['127.0.0.1:9092'],
    logger: Rails.logger
  }
end

KAFKA_TOPIC = 'tweets'
