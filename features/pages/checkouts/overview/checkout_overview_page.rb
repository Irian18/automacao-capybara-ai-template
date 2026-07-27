class CheckoutOverviewPage < SitePrism::Page
  element :label_payment_inf, '[data-test="payment-info-label"]'
  element :value_payment_inf, '[data-test="payment-info-value"]'
  element :label_shipping_inf, '[data-test="shipping-info-label"]'
  element :value_shipping_inf, '[data-test="shipping-info-value"]'
  element :label_prince_total, '[data-test="total-info-label"]'
  element :value_prince_total, '[data-test="subtotal-label""]'
  element :value_tax, '[data-test="tax-label"]'
  element :value_total, '[data-test="total-label"]'
  element :btn_cancel, '#cancel'
  element :btn_finish, '#finish'
  element :feedback_error, '[data-test="error"]'

  section :primary_header, PrimaryHeader, 'data-test="primary-header"'
  section :secondary_header, SecondaryHeaderSection, '[data-test="secondary-header"]'

end