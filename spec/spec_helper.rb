RSpec.configure do |config|
  config.mock_with :rr
  def config.fixture_path()  @fixture_path ||= File.dirname(__FILE__)+'/fixtures'  end
  Dir[File.dirname(__FILE__)+'/support/**/*.rb'].each { |f| require f }
end

