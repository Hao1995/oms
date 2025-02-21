require 'json'

class Event
  attr_accessor :type, :data, :timestamp

  def initialize(type, data, timestamp = Time.now.to_i)
    @type = type
    @data = data
    @timestamp = timestamp
  end

  def to_json()
    {
      type: @type,
      data: @data,
      timestamp: @timestamp
    }.to_json
  end

  def self.from_json(json)
    parsed = JSON.parse(json)
    new(parsed['type'], parsed['data'], parsed['timestamp'])
  end
end
