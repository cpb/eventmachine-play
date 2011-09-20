Bundler.setup(:development)
require 'eventmachine'

module ShellExtension
  def em(&block)
    EM.run do
      block.call
      shutdown_if_no_timers = proc {
        if EM.instance_variable_get("@timers").empty?
          EM.stop_event_loop
        else
          puts "waiting for timmers..."
          EM.add_timer(1, &shutdown_if_no_timers)
        end
      }
      EM.schedule(&shutdown_if_no_timers)
    end
  end
end

extend ShellExtension
