require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "eventmachine_play/js_like"

describe EventmachinePlay::JsLike do
  include EM::SpecHelper

  let(:example_emitter) do
    Class.new do
      include EventmachinePlay::JsLike
    end.new
  end

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
          puts "hello?"
          calls += 1
          args.push([one,two])
          done
        }

        expect {
          example_emitter.trigger_event(:meow,1,2)
        }.to change { calls }.by(1)
      end

      args.first.should eql([1,2])
    end
  end
end
