# frozen_string_literal: true

# If you do not include FactoryBot::Syntax::Methods in your test suite,
# then all factory_girl methods will need to be prefaced with FactoryBot.
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
