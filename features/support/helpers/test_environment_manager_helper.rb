module TestEnvironmentManagerHelper
  def exec_teardown
    # Implemente a limpeza de dados do seu projeto aqui.
    # Exemplo: clients.delete_all
    puts '[test_environment_manager] exec_teardown não configurado'
  end

  def has_tag_in_scenario?(name_tag:)
    Array($all_scenario_tags).include?(name_tag)
  end

  def terminate_chrome_browser
    system('pkill chrome') if CONFIG['headless_mode']
  end

  private

  def run_unless_prod_performance
    return if ENV['ENVIRONMENT_TYPE'] == 'prod_performance'

    yield
  end
end
