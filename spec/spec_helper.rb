require 'rspec'
require 'rr'

require 'tavern'

RSpec.configure do |config|
  config.mock_with :rr
end