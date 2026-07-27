module HashHelper
  def initialize_array_tags_scenario(tags_scenario: nil)
    $tags_scenario ||= {}
    $tags_scenario = tags_scenario
  end

  def tags_scenario
    $tags_scenario
  end

  def self.initialize_hash_credentials
    $access_credentials ||= {}
  end

  def set_access_credentials(credentials: nil)
    $access_credentials = credentials
  end

  def access_credentials
    $access_credentials
  end

  def self.initialize_hash_response_error
    $response_error ||= {}
  end

  def hash_response_error
    $response_error
  end

  def self.initialize_hash_response_full
    $response_full ||= {}
  end

  def hash_response_full
    $response_full
  end
end
