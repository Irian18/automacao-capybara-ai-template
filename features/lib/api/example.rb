module Api
  class Example < ::Api::Base
    ROUTE = '/api/v1/examples'.freeze

    def create(body: nil)
      options = options_with_query(@options_api_v1, nil, body.to_h.to_json)
      self.class.post(ROUTE, options)
    end

    def index(query: {})
      options = options_with_query(@options_api_v1, query, nil)
      self.class.get(ROUTE, options)
    end

    def update(query: {}, body: nil)
      options = options_with_query(@options_api_v1, query, body.to_h.to_json)
      self.class.put(ROUTE, options)
    end

    def delete(query: {})
      options = options_with_query(@options_api_v1, query, nil)
      self.class.delete(ROUTE, options)
    end
  end
end
