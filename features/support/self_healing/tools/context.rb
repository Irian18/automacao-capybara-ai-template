module SelfHealing
  module Tools
    Context = Struct.new(:session, :page_object, :helper, keyword_init: true)
  end
end
