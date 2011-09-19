require 'active_support/concern'
require 'active_support/memoizable'
require 'eventmachine_play/callback_based_channel'

module EventmachinePlay
  module JsLike
    extend ActiveSupport::Concern

    module InstanceMethods
    extend ActiveSupport::Memoizable

      def initialize(*args,&block)
        super
        @js_like_channels = Hash.new do |hash,key|
          CallbackBasedChannel.new.tap do |new_channel|
            hash.merge!(key => new_channel)
          end
        end
      end

      def add_event(event_name, object=nil, meth=nil, &block)
        channel_for(event_name).subscribe(make_callback(object, meth, block))
      end

      def remove_event(event_name, object=nil, meth=nil, &block)
        channel_for(event_name).unsubscribe(make_callback(object, meth, block))
      end

      def trigger_event(event_name, *args)
        channel_for(event_name).push(args)
      end

      private
        def channel_for(event_name)
          @js_like_channels.fetch(event_name.to_sym) do |key|
            @js_like_channels.default(key)
          end
        end

        def make_callback(object, method, block)
          # not & block because memoize doesn't work with blocks
          EM::Callback(object, method,&block)
        end
        memoize :make_callback
    end
  end
end
