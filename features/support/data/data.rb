require 'json'
require 'yaml'
require 'ostruct'

module Header
  def headers
    @headers = {
      "Content-type": 'application/json',
      "Authorization": CONFIG['token_api'] || ''
    }
  end

  def headers_v1
    @headers = {
      "Content-type": 'application/json',
      "Authorization": CONFIG['token_v1'] || ''
    }
  end
end

class Head
  include Header
end
