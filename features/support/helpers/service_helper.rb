Dir[File.join(File.dirname(__FILE__), '../../services/*.rb')].each { |file| require file }

module AppServices
  # Adicione seus serviços aqui conforme o domínio da aplicação.
  # Exemplo:
  # def users
  #   @users ||= UsersService.new
  # end
end
