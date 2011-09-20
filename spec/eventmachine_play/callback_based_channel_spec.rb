require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "eventmachine_play/callback_based_channel"

describe EventmachinePlay::CallbackBasedChannel do
  include EM::SpecHelper

  let(:channel) do
    EventmachinePlay::CallbackBasedChannel.new
  end

  before(:each) do
    @calls = 0
  end

  def handler(*args, &block)
    EM::Callback(*args, &block)
  end

  it "should allow subscribers" do
    em do
      first = handler() do |one, two|
        one.should eql(1)
        two.should eql(2)
        @calls += 1
      end

      second = handler() do |o, t|
        @calls += 1
        done
      end

      channel.subscribe(first)

      channel.subscribe(second)

      channel.push([1,2])
    end
    @calls.should eql(2)
  end

  it "should allow unsubscription" do
    em do
      first = handler() do |one, two|
        @calls += 1
      end

      second = handler() do |one, two|
        fail("Should not be called")
      end

      channel.subscribe(first)
      channel.subscribe(second)

      channel.unsubscribe(second)
      channel.push([1,2])
      done
    end

    @calls.should eql(1)
  end

  it "should not allow duplicate subscriptions" do
    em do
      first = handler() do |one, two|
        one.should eql(1)
        two.should eql(2)

        @calls += 1
      end

      second = handler() do |one, two|
        @calls += 1
        done
      end

      channel.subscribe(first)
      channel.subscribe(first)

      channel.subscribe(second)


      channel.push([1,2])
    end
    @calls.should eql(2)
  end
end
