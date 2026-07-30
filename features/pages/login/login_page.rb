class LoginPage < SitePrism::Page
  include Capybara::DSL
  include Capybara::RSpecMatchers

  set_url '/'

  element :in_user_id, '#user-name'
  element :in_user_data_test, 'input[data-test="usernameee"]'
  element :in_password_id, '#password'
  element :in_password_data_test, 'input[data-test="password"]'
  element :bt_submit_id, '#login-button'
  element :bt_submit_id_data_test, '[data-test="login-button"]'
  element :msg_error_containet, '.error-message-container'

  def logar_usuario(user, password)
    in_user_id.set(user)
    in_password_id.set(password)
    bt_submit_id.click
  end

  def load_and_wait
    load
  end
end
