class AgentWorker
  def self.start(agent_name)
    Rails.logger.info "Worker started, waiting for messages..."

    loop do
      agent = Agent::Factory.get_agent(agent_name)

      channel = RabbitMQConnection.create_channel
      queue = channel.queue(agent_name, durable: true)
      queue.subscribe(block: true, manual_ack: true) do |delivery_info, _properties, body|
        begin
          event = Event.from_json(body)
          case event.type
          when Event::TYPE[:create_campaign]
            response = agent.create_campaign(event.data)
            # @todo insert to our database
          when Event::TYPE[:update_campaign]
            response = agent.update_campaign(event.data)
          else
            Rails.logger.warn "[AgentWorker] Unsupported event type: #{event.type}"
            response = nil
          end

          if response && response.code.to_i == 200
            Rails.logger.debug "[AgentWorker] Successfully processed event: #{event.to_json}"
            channel.ack(delivery_info.delivery_tag)
          else
            Rails.logger.error "[AgentWorker] Failed to process event: #{event.to_json}, Response: #{response&.body}"
            channel.nack(delivery_info.delivery_tag, false, true)
          end
        rescue => e
          Rails.logger.error "[AgentWorker] Error: #{e.message}"
          channel.nack(delivery_info.delivery_tag, false, true)
        end
      end
    end
  end
end