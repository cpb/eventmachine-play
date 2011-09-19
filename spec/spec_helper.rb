$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

Bundler.require
require "em-spec/rspec"

require "eventmachine_play"
# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  include TemporaryFileHelpers

  config.before(:each) do
    Pathname.pwd.join("tmp/spec").mkpath
  end

  config.after(:each) do
    Pathname.pwd.join("tmp/spec").rmtree
  end
end
