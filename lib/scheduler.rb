#!/usr/bin/env ruby
# lib/scheduler.rb

# Load the Rails environment so you can access your models
require File.expand_path('../config/environment', __dir__)
require 'rufus-scheduler'

# Create a new Rufus-scheduler instance
scheduler = Rufus::Scheduler.new

# Schedule a job to run every 10 minutes
scheduler.every '3s' do
  # Insert a new Campaign record
  AgentSyncOutbox.where(status: false).find_each do |record|
    channel = RabbitMQConnection.create_channel

    exchange = channel.exchange('campaign_exchange', type: 'fanout')

    event = Event.new(record.event_type, record.payload)
    exchange.publish(event.to_json, persistent: true)
    
    record.update!(status: true)
  rescue => e
    Rails.logger.error("Failed to send event: #{e.message}")
  end
  Rails.logger.info "Send event successfully - #{Time.current}"
end

# Keep the script running so the scheduler can continue processing jobs
scheduler.join
