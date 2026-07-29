base = File.join(File.dirname(__FILE__), '../pages')

sections = Dir[File.join(base, 'section/**/*.rb')].sort
pages    = Dir[File.join(base, '**/*.rb')].sort - sections

(sections + pages).each { |file| require file }

module Pages
  def login
    @login ||= LoginPage.new
  end

  def products
    @products ||= ProductsPage.new
  end

  def your_cart
    @your_cart ||= YourCartPage.new
  end

  def checkout
    @checkout ||= CheckoutPage.new
  end

  def checkout_overview
    @checkout_overview ||= CheckoutOverviewPage.new
  end

  def checkout_complete
    @checkout_complete ||= CheckoutCompletePage.new
  end

  def footer
    @footer ||= FooterPage.new
  end
end
