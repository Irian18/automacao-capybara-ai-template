module CredentialsHelper
  AUTH_MODES = {
    'cookie' => 'cookie',
    'token_headers' => 'token_headers'
  }.freeze

  def generate_access_credentials_v1(email:, password:)
    response = login_service.login(email:, password:)
    auth_mode = ENV['AUTH_MODE'] || CONFIG['auth_mode'] || 'cookie'

    case auth_mode
    when 'cookie'
      set_cookie = response.headers['set-cookie']
      raise '[CredentialsHelper] set-cookie não encontrado na resposta' unless set_cookie

      cookie_parts = set_cookie.split(';')
      token_part = cookie_parts.first

      set_access_credentials(credentials: { set_cookie: token_part })
    when 'token_headers'
      client = response.headers['client']
      access_token = response.headers['access-token']
      uid = response.headers['uid']

      set_access_credentials(credentials: { client:, access_token:, uid: })
    else
      raise "Unknown auth mode: #{auth_mode}"
    end
  end

  def headers_request_v1
    raise 'Access credentials not defined' if access_credentials.nil?

    auth_mode = ENV['AUTH_MODE'] || CONFIG['auth_mode'] || 'cookie'

    case auth_mode
    when 'cookie'
      cookie_value = access_credentials[:set_cookie]
      raise '[CredentialsHelper] set_cookie não encontrado nas credenciais' unless cookie_value

      {
        headers: {
          'Content-Type' => 'application/json',
          'Cookie' => cookie_value,
          'Origin' => CONFIG['url_home']
        }
      }.to_hash
    when 'token_headers'
      {
        headers: {
          'Content-Type' => 'application/json',
          'client' => access_credentials[:client],
          'access-token' => access_credentials[:access_token],
          'uid' => access_credentials[:uid]
        }
      }.to_hash
    else
      raise "Unknown auth mode: #{auth_mode}"
    end
  end
end
