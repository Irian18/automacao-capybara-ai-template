class ExampleService
  def initialize
    @api = ::Api::Example.new
  end

  def create(body:)
    response = @api.create(body:)
    expect_response_success?(response:)
    response
  end

  def index(query: {})
    response = @api.index(query:)
    expect_response_success?(response:)
    response
  end

  def update(query: {}, body: nil)
    response = @api.update(query:, body:)
    expect_response_success?(response:)
    response
  end

  def delete(query: {})
    response = @api.delete(query:)
    expect_response_success?(response:)
    response
  end
end
