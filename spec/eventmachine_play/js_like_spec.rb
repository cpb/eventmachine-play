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

  context "trigger event" do
    it "only triggers responders for the triggered event" do
      dog_catcher.should_not_receive(:heard_something).with(1,2)

      em do
        example_emitter.add_event(:bark, dog_catcher, :heard_something)

        example_emitter.add_event(:meow) do |*args|
          done
        end

        example_emitter.trigger_event(:meow,"quietly")
      end
    end

    it "only triggers a responder as many times as event is triggered" do
      dog_catcher.should_receive(:heard_something).with(anything()).exactly(3).times

      calls = 0
      em do
        example_emitter.add_event(:bark, dog_catcher, :heard_something)
        example_emitter.add_event(:bark) do |*args|
          done if (calls += 1) >= 3
        end
        example_emitter.trigger_event(:bark,:something)
        example_emitter.trigger_event(:bark,:something)
        example_emitter.trigger_event(:bark,:something)
      end
    end
  end

  context "removing events" do
    it "will no longer have the responders triggered by the event" do
      dog_catcher.should_not_receive(:heard_something).with(1,2)

      em do
        example_emitter.add_event(:meow, dog_catcher, :heard_something)

        example_emitter.add_event(:meow) do |*args|
          done
        end

        example_emitter.remove_event(:meow, dog_catcher, :heard_something)

        example_emitter.trigger_event(:meow,"quietly")
      end
    end
  end

  context "adding events" do
    it "will have the responders triggered with arguments" do
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

    it "called multiple times will add multiple responders" do
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

    it "called multiple times with the same responder, only adds it once" do
      dog_catcher.should_receive(:heard_something).with(1,2).once

      em do
        example_emitter.add_event(:bark, dog_catcher, :heard_something)
        example_emitter.add_event(:bark, dog_catcher, :heard_something)
        example_emitter.add_event(:bark) do |*args|
          done
        end
        example_emitter.trigger_event(:bark,1,2)
      end
    end
  end
end
