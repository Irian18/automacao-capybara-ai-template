class CheckoutPage < SitePrism::Page
  element :in_first_name, '#first-name'
  element :in_last_name, '#last-name'
  element :in_posta_code, '#postal-code'
  element :btn_cancel, '#cancel'
  element :btn_coontinue, '#continue'

  section :primary_header, PrimaryHeader, 'data-test="primary-header"'
  section :secondary_header, SecondaryHeaderSection, '[data-test="secondary-header"]'

end