class EventPublisher
  def self.publish(topic, event)
    channel = RabbitMQConnection.create_channel
    exchange = channel.exchange(topic, type: 'fanout', durable: true)

    exchange.publish(event, persistent: true)
    Rails.logger.info "Published topic: #{topic}, event: #{event}"
  end
end