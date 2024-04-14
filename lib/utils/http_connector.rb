# frozen_string_literal: true

require "faraday"

class HttpConnector
  REQUEST_TIMEOUT = 5

  @connection = Faraday.new { _1.options.timeout = REQUEST_TIMEOUT }

  def self.get(url)
    begin
      response = @connection.get(url)
    rescue Faraday::ConnectionFailed
      puts "Request timeout"
      return nil
    end

    if response.status != 200
      puts "Error: #{response.status}"
      return nil
    end

    response.body
  end
end
