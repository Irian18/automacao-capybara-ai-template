class PrimaryHeader < SitePrism::Section
  element :label_page_title, '[data-test="title"]'
  element :lnk_shopping_cart, '[data-test="shopping-cart-link"]'
  element :btn_menu, '#react-burger-menu-btn'
  element :label_shopping_cart_badge, '[data-test="shopping-cart-badge"]'

  def add_to_cart
    add_to_cart_button.click
  end
end