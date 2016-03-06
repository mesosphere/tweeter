# Kafka config
hosts = (ENV['KAFKA_BROKERS'] || '127.0.0.1:9092').split(',')

KAFKA_OPTIONS = {
  seed_brokers: hosts,
  logger: Rails.logger
}

KAFKA_TOPIC = 'tweets'
