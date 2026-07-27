class Helpful
  @instance = new

  private_class_method :new

  class << self
    attr_reader :instance
  end

  @id = {}
  @external_id = {}
  @description = {}

  class << self
    attr_reader :id
  end

  class << self
    attr_reader :external_id
  end

  class << self
    attr_reader :description
  end
end
