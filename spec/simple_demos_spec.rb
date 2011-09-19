require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Simple Demos" do
  include EM::SpecHelper

  it "EM.add_timer(0.5) should add a timer which executes in about half a second" do
    start = Time.now

    em do
      EM.add_timer(0.5) {
        (Time.now - start).should be_within(0.1).of(0.5)
        done
      }
    end
  end

  it "EM.add_periodic_timer(0.5) should add a timer which every half second until canceled" do
    num = 0
    start = Time.now

    em do
      timer = EM.add_periodic_timer(0.5) {
        if (num += 1) == 2
          (Time.now - start).should be_within(0.1).of(1.0)
          timer.cancel
          done
        end
      }
    end
  end

  context "EM::Deferrable" do
    let(:deferrable) { EM::DefaultDeferrable.new }

    context "#succeed" do
      it "should pass succeeded arguments to the callback blocks" do
        first_called_with = []
        calls = 0

        em do
          deferrable.callback do |one,two|
            first_called_with.push(one,two)
            calls += 1
          end

          deferrable.callback do |one,two|
            first_called_with.should eql([one,two])
            calls += 1
            done
          end

          deferrable.succeed(1,2)
          calls.should eql(2)
        end
      end

      it "should not call errback blocks" do
        em do
          deferrable.errback do |one,two|
            fail("I wasn't supposed to be called")
          end

          deferrable.succeed(1,2)
          done
        end
      end

      it "should call callbacks declared after success" do
        first_called_with = []
        calls = 0

        em do
          deferrable.callback do |one,two|
            first_called_with.push(one,two)
            calls += 1
          end

          deferrable.succeed(1,2)

          deferrable.callback do |one,two|
            first_called_with.should eql([one,two])
            calls += 1
            done
          end

          calls.should eql(2)
        end
      end
    end

    context "#timeout" do
      it "should call errbacks without any arguments when the timeout expires" do
        calls = 0

        em do
          deferrable.errback do
            calls += 1
          end

          deferrable.timeout(1)

          deferrable.errback do
            calls.should eql(1)
            calls += 1
          end

          EM.add_timer(1) do
            calls.should eql(2)
            done
          end
        end
      end
    end
  end

  context "EM::Channel" do
    let(:channel) { EM::Channel.new }

    before(:each) do
      @calls = 0
    end

    it "should allow subscribers" do
      em do
        channel.subscribe { |arg|
          arg.should eql([1,2])
          @calls += 1
        }

        channel.subscribe do |arg|
          @calls += 1
          done
        end

        channel.push([1,2])
      end
      @calls.should eql(2)
    end

    it "should allow unsubscription" do
      em do
        channel.subscribe do |arg|
          @calls += 1
        end

        subscriber = channel.subscribe do |arg|
          fail("Should not be called")
        end

        channel.unsubscribe(subscriber)
        channel.push([1,2])
        done
      end

      @calls.should eql(1)
    end
  end

  context "EM::Callback" do
    def handler(*args, &block)
      EM::Callback(*args, &block)
    end

    def responder(one,two)
      @responder_calls += 1
      @responder_args.push([one,two])
    end

    let(:responder_block) { proc { |one,two|
      @responder_block_calls += 1
      @responder_block_args.push([one,two])
    } }

    let(:responder_object) do
      Class.new do
        attr_reader :calls,:args

        def initialize
          @calls = 0
          @args = []
        end

        def responder(one,two)
          @calls += 1
          @args.push([one,two])
        end
      end.new
    end

    before(:each) do
      @responder_calls = 0
      @responder_args = []
      @responder_block_calls = 0
      @responder_block_args = []
    end

    it "should accept a call-able block" do
      calls = 0
      args = []

      callable = handler do |one,two|
        calls += 1
        args.push([one,two])
      end

      expect {
        callable.call(1,2)
      }.to change { calls }.by(1)

      args.first.should eql([1,2])
    end

    it "should accept a proc" do
      callable = handler(responder_block)

      expect {
        callable.call(1,2)
      }.to change { @responder_block_calls }.by(1)

      @responder_block_args.first.should eql([1,2])
    end

    it "should accept a method object" do
      callable = handler(method(:responder))

      expect {
        callable.call(1,2)
      }.to change { @responder_calls }.by(1)

      @responder_args.first.should eql([1,2])
    end

    it "should accept an object's method" do
      callable = handler(responder_object.method(:responder))

      expect {
        callable.call(1,2)
      }.to change { responder_object.calls }.by(1)

      responder_object.args.first.should eql([1,2])
    end
  end
end
