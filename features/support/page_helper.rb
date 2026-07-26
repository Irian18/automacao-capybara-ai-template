Dir[File.join(File.dirname(__FILE__), '../pages/**/*.rb')].sort.each { |file| require file }

module Pages
  # Adicione seus page objects aqui conforme o domínio da aplicação.
  # Exemplo:
  # def login
  #   @login ||= LoginPage.new
  # end
end
