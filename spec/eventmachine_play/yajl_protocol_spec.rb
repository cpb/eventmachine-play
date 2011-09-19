require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "eventmachine_play/yajl_protocol"

class ExampleClient
  include ::EventmachinePlay::YajlProtocol
end

class JsonAble < Struct.new(:id, :name)
  def to_json
    Yajl::Encoder.encode({:id => id, :name => name})
  end
end

describe EventmachinePlay::YajlProtocol do

  def pack_message(message)
    # peaked at source of EM::P::ObjectProtocol
    [message.bytesize, message].pack('Na*')
  end

  let(:example_client) { ExampleClient.new }

  context "receiving json" do
    let(:data) { pack_message('{"foobar": "snacks"}') }

    it "should call receive_object with the deserialized object" do
      example_client.should_receive(:receive_object).with(hash_including('foobar' => 'snacks'))
      example_client.receive_data(data)
    end
  end

  context "sending objects" do
    it "should call send_data with the encoded and packed object" do
      example_client.should_receive(:send_data).with(pack_message('{"cats":"purrr"}'))
      example_client.send_object({:cats => 'purrr'})
    end
  end

  context "between a client and server" do
    include EventMachine::SpecHelper

    it "should be able to send objects which respond to to_json" do
      module Server
        include ::EventmachinePlay::YajlProtocol

        def post_init
          puts "server received connection"
          send_object(JsonAble.new(1,:caleb))
        end
      end

      module Client
        include ::EventmachinePlay::YajlProtocol

        def initialize(example, expectation_block)
          @example = example
          @expectation_block = expectation_block
        end

        def post_init
          puts "client connected"
        end

        def receive_object(object)
          @expectation_block.call(object)
          #EM.stop_event_loop
          @example.done
        end
      end

      em do
        EM.start_server("127.0.0.1",4000, Server)

        EM.connect("127.0.0.1",4000, Client,self,proc { |object|
          object.should include("id" => 1, "name" => "caleb")
        })
      end
    end
  end
end
