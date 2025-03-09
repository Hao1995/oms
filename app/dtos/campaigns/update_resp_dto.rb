module Campaigns
  class UpdateRespDto
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :success, :boolean
    attribute :action, :string
    attribute :message, :string

    def initialize(success, action, message)
      super(success: success, action: action, message: message)
    end

    def to_h
      attributes.compact
    end
  end
end
