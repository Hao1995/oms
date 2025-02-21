require 'bunny'
require Rails.root.join('app/services/agent/queue_setup')

class RabbitMQConnection
  def self.create_connection
    @connection ||= Bunny.new(automatically_recover: true)
    @connection.start
    @connection
  end

  def self.create_channel
    @channel ||= create_connection.create_channel
  end
end

Agent::QueueSetup.setup