module Types
  include Dry.Types()
end

class Example < Dry::Struct
  attribute :name, Types::String.optional.default { Faker::Name.name }.freeze
  attribute :email, Types::String.optional.default { Faker::Internet.email }.freeze
  attribute :active, Types::Bool.optional.default(true)
end
