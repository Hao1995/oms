require 'json'

class AgentWorker
  def self.start(agent_name)
    Rails.logger.info "Worker started, waiting for messages..."

    agent = Agent::Factory.get_agent(agent_name)
    rate_limit = YAML.load_file('config/agents.yml')['agents'][agent_name]['rate_limit']

    channel = RabbitMQConnection.create_channel
    queue = channel.queue(agent_name, durable: true)

    queue.subscribe(block: true, manual_ack: true) do |delivery_info, _properties, body|
      begin
        event = Event.from_json(body)
        data = JSON.parse(event.data)
        Rails.logger.info "[AgentWorker] Event: #{event}"

        case event.type
        when Event::TYPE[:create_campaign]
          response = agent.create_campaign(data)
        when Event::TYPE[:update_campaign]
          response = agent.update_campaign(data)
        else
          Rails.logger.warn "[AgentWorker] Unsupported event type"
          response = nil
        end

        if response && response.code.to_i == 201
          Rails.logger.debug "[AgentWorker] Successfully processed event"
        elsif response && response.code.to_i == 429
          Rails.logger.info "[AgentWorker] Ratelimiter is triggered, wait #{rate_limit[:interval_sec]} ... "
          sleep(rate_limit[:interval_sec])
        else
          Rails.logger.error "[AgentWorker] Failed to process event, sending to dead queue. Response: #{response&.body}"
          # @todo send to dead queue
        end
        channel.ack(delivery_info.delivery_tag)
      rescue => e
        Rails.logger.error "[AgentWorker] Error: #{e.message}"
        channel.nack(delivery_info.delivery_tag, false, true)
      end
    end
  end
end
