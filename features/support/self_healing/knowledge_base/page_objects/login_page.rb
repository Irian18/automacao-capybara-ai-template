# frozen_string_literal: true

# Cópia de referência do Page Object real:
# features/pages/login/login_page.rb
#
# Este arquivo é usado pelo RAG para manter consistência na geração
# de novos Page Objects. Não deve ser carregado diretamente nos testes.

require 'site_prism'

class LoginPage < SitePrism::Page
  include Capybara::DSL
  include Capybara::RSpecMatchers

  set_url '/login'

  element :tf_email, '#email'
  element :tf_password, '#password'
  element :bt_login, '#login-button'

  def logar_usuario(email, senha)
    tf_email.set(email)
    tf_password.set(senha)
    bt_login.click
  end

  def load_and_wait
    load
  end
end
