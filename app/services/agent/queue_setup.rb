require 'bunny'
require 'yaml'

module Agent
  class QueueSetup
    NAME = "campaign_exchange"

    def self.agents
      @agents ||= YAML.load_file(Rails.root.join('config/agents.yml'))['agents']
    end

    def self.setup
      agents.each do |key, value|
        channel = RabbitMQConnection.create_channel
        exchange = channel.exchange(NAME, type: 'fanout', durable: true)
        
        # Declare a durable queue for each agent
        queue = channel.queue(value["name"], durable: true)
        queue.bind(exchange)

        Rails.logger.info "[AgentQueueSetup] Queue '#{value["name"]}' is bound to durable exchange."
      end
    end
  end
end