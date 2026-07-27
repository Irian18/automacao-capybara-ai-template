class CartItemSection < SitePrism::Section
  element :label_quantity, '[data-test="item-quantity"]'
  element :label_title, '[data-test="inventory-item-name"]'
  element :label_description, '[data-test="inventory-item-desc"]'
  element :label_price, '[data-test="inventory-item-price"]'
  element :btn_remove_button_id, '#remove-sauce-labs-backpack'

  def remove
    remove_button.click
  end
end

class YourCartPage < SitePrism::Page
  set_url '/cart.html'

  element :page_title, '[data-test="title"]'
  element :btn_continue_shopping, '[data-test="continue-shopping"]'
  element :btn_checkout, '[data-test="checkout"]'
  element :btn_continue_shopping_id, '#continue-shopping'
  element :btn_checkout_id, '#checkout'

  sections :cart_items, CartItemSection, '[data-test="inventory-item"]'
  section :primary_header, PrimaryHeader, 'data-test="primary-header"'
  section :secondary_header, SecondaryHeaderSection, '[data-test="secondary-header"]'

  def go_to_checkout
    checkout_button.click
  end

  def continue_shopping
    continue_shopping_button.click
  end

  def find_cart_item_by_name(name)
    cart_items.find { |item| item.title.text == name }
  end
end