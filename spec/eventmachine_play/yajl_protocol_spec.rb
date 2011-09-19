require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "eventmachine_play/yajl_protocol"

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

  let(:example_client) do
    Class.new { include ::EventmachinePlay::YajlProtocol }.new
  end

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

    let(:socket) { in_temporary_path("yajl_socket").to_s }
    let(:client) do
      Class.new(EventMachine::Connection) do
        include ::EventmachinePlay::YajlProtocol
      end
    end

    let(:server) do
      Class.new(EventMachine::Connection) do
        include ::EventmachinePlay::YajlProtocol
      end
    end

    it "should be able to send objects which respond to to_json" do
      server.class_eval do
        def post_init
          send_object(JsonAble.new(1,:caleb))
        end
      end


      client.any_instance.should_receive(:receive_object) do |object|
        object.should include("id" => 1, "name" => "caleb")
        done
      end

      em do
        EM.start_server(socket, server)

        EM.connect(socket, client)
      end
    end
  end
end
