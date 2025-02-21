class Campaign < ApplicationRecord
  validates :customer_id, presence: true
  validates :title, presence: true, length: { maximum: 40 }
  validates :currency, inclusion: { in: %w[USD TWD] }
  validates :budget, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :advertiser_id, presence: true

  after_commit :trigger_create_campaign_event, on: :create
  after_commit :trigger_update_campaign_event, on: :update

  def trigger_create_campaign_event
    event = Event.new(Event::TYPE[:create_campaign], self.to_json)
    EventPublisher.publish('campaign_exchange', event.to_json)
  end

  def trigger_update_campaign_event
    event = Event.new(Event::TYPE[:update_campaign], self.to_json)
    EventPublisher.publish('campaign_exchange', event.to_json)
  end
end
  