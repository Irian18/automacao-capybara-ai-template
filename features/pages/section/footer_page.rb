class FooterPage < SitePrism::Page
  element :lnk_twitter, '[data-test="social-twitter"]'
  element :lnk_facebook, '[data-test="social-facebook"]'
  element :lnk_linkedin, '[data-test="social-linkedin"]'
  element :label_copy, '[data-test="footer-copy"]'
end
