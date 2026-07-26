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
