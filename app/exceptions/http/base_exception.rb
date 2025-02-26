module Http
  class BaseException < StandardError
    attr_accessor :status_code, :response_body

    def initialize(status_code, response_body, message = nil)
      @status_code = status_code
      @response_body = response_body
      super(message || "HTTP #{status_code}: #{response_body}")
    end
  end
end
