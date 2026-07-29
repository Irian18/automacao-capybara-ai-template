class CheckoutPage < SitePrism::Page
  element :in_first_name, '#first-name'
  element :in_last_name, '#last-name'
  element :in_postal_code, '#postal-code'
  element :btn_cancel, '#cancel'
  element :btn_continue, '#continue'

  section :primary_header, PrimaryHeader, '[data-test="primary-header"]'
  section :secondary_header, SecondaryHeaderSection, '[data-test="secondary-header"]'
end
