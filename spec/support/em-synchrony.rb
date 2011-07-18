RSpec.configure do |config|
  config.around(:each, :em_synchrony => true) do |example|
    EM.synchrony do
      example.call
      EM.stop
    end
  end
end

