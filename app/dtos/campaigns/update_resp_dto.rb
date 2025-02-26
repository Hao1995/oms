module Campaigns
  class UpdateRespDto
    attr_reader :success, :action, :message

    def initialize(success, action, message)
      @success = success
      @action = action
      @message = message
    end

    def to_h
      {
        success: @success,
        action: @action,
        message: @message
      }
    end
  end
end
