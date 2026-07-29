class CheckoutCompletePage < SitePrism::Page
  element :btn_back_products, '#back-to-products'

  section :primary_header, PrimaryHeader, '[data-test="primary-header"]'
  section :secondary_header, SecondaryHeaderSection, '[data-test="secondary-header"]'
end
