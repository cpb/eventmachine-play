require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "eventmachine_play/js_like"

describe EventmachinePlay::JsLike do
  include EM::SpecHelper

  let(:example_emitter) do
    Class.new do
      include EventmachinePlay::JsLike
    end.new
  end

  let(:dog_catcher) { double("Dog Catcher") }

  context "private methods" do
    it "should only create one channel per event name" do
      example_emitter.send(:channel_for,:event_name).should eql(example_emitter.send(:channel_for,"event_name"))
    end

    it "should only create one callback per block" do
      callme = proc {|arg| puts arg }
      example_emitter.send(:make_callback,nil,nil,callme).should eql(example_emitter.send(:make_callback,nil,nil,callme))
    end
  end
  context "adding events" do

    it "allow you to to add events" do
      calls = 0
      args = []

      em do
        example_emitter.add_event(:meow) { |one,two|
          calls += 1
          args.push([one,two])
          done
        }

        example_emitter.trigger_event(:meow,1,2)
      end
      calls.should eql(1)
      args.first.should eql([1,2])
    end

    it "allows you to add multiple responders" do
      calls = 0

      dog_catcher.should_receive(:heard_something).with(1,2).once

      em do
        example_emitter.add_event(:bark) { |*arg|
          calls += 1
        }

        example_emitter.add_event(:bark,dog_catcher,:heard_something)

        example_emitter.add_event(:bark) do |*args|
          done
        end

        example_emitter.trigger_event(:bark,1,2)
      end

      calls.should eql(1)
    end

    it "only triggers the event's responders" do
      dog_catcher.should_not_receive(:heard_something).with(1,2)

      em do
        example_emitter.add_event(:bark, dog_catcher, :heard_something)

        example_emitter.add_event(:meow) do |*args|
          done
        end

        example_emitter.trigger_event(:meow,"quietly")
      end
    end
  end
end
