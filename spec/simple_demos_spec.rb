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
end
