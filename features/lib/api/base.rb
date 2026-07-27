require 'httparty'

module Api
  class Base
    include HTTParty

    def initialize
      @options_api_v1 = headers_request_v1
    end

    def options_with_query(options, query, body)
      opts = options.dup
      opts[:query] = query if query && !query.empty?
      opts[:body] = body if body
      opts
    end
  end
end
