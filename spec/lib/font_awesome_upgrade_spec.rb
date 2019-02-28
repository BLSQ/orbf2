require "rails_helper"

RSpec.describe "Font Awesome" do
  it 'alerts the developer if font-awesome-rails ever goes away' do
    unless defined?(FontAwesome::Rails)
      message = <<STR
font-awesome-rails is dead, long live font-awesome!

Great, font-awesome-rails disappeared from out stack. Less great is that now no one is providing us with the font-awesome assets. So to fix that:

- Add the font-awesome-sass gem
- Remove our icon-helper
- Look for fa5 and fix those
- Remove this test

Profit!
STR
      fail message
    end
  end
end
