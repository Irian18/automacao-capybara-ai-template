class SecondaryHeaderSection < SitePrism::Section
  element :btn_product_sort_container, '[data-test="product-sort-container"]'
  element :span_title, '[data-test="title"]'

  def sort_by(option_text)
    btn_product_sort_container.select(option_text).text
  end
end