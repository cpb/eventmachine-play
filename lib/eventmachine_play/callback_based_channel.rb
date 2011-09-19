module EventmachinePlay
  class CallbackBasedChannel < EM::Channel
    def initialize(*args)
      super
      @callback_map = {}
    end

    def subscribe(callable)
      @callback_map.fetch(callable) do |key|
        subscribed_proc = proc do |arg|
          callable.call(*arg)
        end

        subscriber_id = super(&subscribed_proc)

        @callback_map.merge!(key => subscriber_id)
        subscriber_id
      end
    end

    def unsubscribe(callable)
      @callback_map.delete(callable).tap do |subscriber_id|
        super(subscriber_id) if subscriber_id
      end
    end
  end
end
