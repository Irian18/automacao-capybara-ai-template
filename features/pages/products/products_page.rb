class InventoryItemSection < SitePrism::Section
  element :label_title, '[data-test^="inventory-item-name"]'
  element :label_description, '[data-test^="inventory-item-desc"]'
  element :label_price, '[data-test^="inventory-item-price"]'
  element :btn_add_to_cart, 'button[data-test^="add-to-cart"]'
  element :btn_remove, 'button[data-test^="remove"]'

  def add_to_cart
    btn_add_to_cart.click
  end


end

class ProductsPage < SitePrism::Page
  set_url '/inventory.html'

  section :primary_header, PrimaryHeader, '[data-test="primary-header"]'
  section :secondary_header, SecondaryHeaderSection, '[data-test="secondary-header"]'
  sections :inventory_items, InventoryItemSection, '[data-test="inventory-item"]'

  def sort_by(option_text)
    secondary_header.sort_by(option_text)
  end

  def find_item_by_name(name)
    inventory_items.find { |item| item.label_title.text.strip == name.strip }
  end

  def menu
    primary_header.btn_menu.click
  end

  def shopping_cart
    primary_header.lnk_shopping_cart.click
  end

  def badge_shopping_cart
    primary_header.label_shopping_cart_badge.text
  end
end
