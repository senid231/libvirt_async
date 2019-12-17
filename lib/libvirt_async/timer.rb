module LibvirtAsync
  class Timer
    # Represents a   When a timer expires, we dispatch the event to
    # libvirt via Libvirt::event_invoke_timeout_callback (feeding it the timer_id
    # we returned from add_timer and the opaque data that libvirt gave us
    # earlier).

    class Monitor
      class Cancelled < StandardError
        def initialize
          super('was cancelled')
        end
      end

      attr_reader :fiber

      def initialize
        @fiber = nil
      end

      def wait(timeout)
        @fiber = Async::Task.current.fiber
        Async::Task.current.sleep(timeout)
        @fiber = nil
      end

      def close
        @fiber.resume(Cancelled.new) if @fiber&.alive?
        @fiber = nil
      end

      def to_s
        "#<#{self.class}:0x#{object_id.to_s(16)} fiber=#{@fiber.&object_id&.to_s(16)} alive=#{@fiber&.alive?}>"
      end

      def inspect
        to_s
      end
    end

    include WithDbg

    attr_reader :timer_id, :opaque, :monitor
    attr_accessor :last_fired, :interval

    def initialize(timer_id, interval, opaque)
      dbg { "#{self.class}#initialize timer_id=#{timer_id}, interval=#{interval}" }

      @timer_id = timer_id
      @interval = interval.to_f / 1000.to_f
      @opaque = opaque
      @last_fired = Time.now.to_f
      @monitor = nil
    end

    def wait_time
      return if interval < 0
      last_fired + interval
    end

    def register
      dbg { "#{self.class}#register starts timer_id=#{timer_id}, interval=#{interval}" }

      if wait_time.nil?
        dbg { "#{self.class}#register no wait time timer_id=#{timer_id}, interval=#{interval}" }
        return
      end

      task = Util.create_task do
        dbg { "#{self.class}#register async starts timer_id=#{timer_id}, interval=#{interval}" }
        now_time = Time.now.to_f
        timeout = wait_time > now_time ? wait_time - now_time : 0
        @monitor = Monitor.new
        cancelled = wait_timer(timeout)

        if cancelled
          dbg { "#{self.class}#register async cancel timer_id=#{timer_id}, interval=#{interval}" }
        else
          dbg { "#{self.class}#register async ready timer_id=#{timer_id}, interval=#{interval}" }
          self.last_fired = Time.now.to_f
          dispatch
        end
      end

      dbg { "#{self.class}#register invokes fiber=0x#{task.fiber.object_id.to_s(16)} timer_id=#{timer_id}, interval=#{interval}" }
      task.run
      dbg { "#{self.class}#register ends timer_id=#{timer_id}, interval=#{interval}" }
    end

    def unregister
      dbg { "#{self.class}#unregister_timer timer_id=#{timer_id}, interval=#{interval}" }

      if @monitor.nil?
        dbg { "#{self.class}#unregister_timer already unregistered timer_id=#{timer_id}, interval=#{interval}" }
        return
      end

      @monitor.close
      @monitor = nil
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} timer_id=#{timer_id} interval=#{interval} last_fired=#{last_fired} monitor=#{monitor}>"
    end

    def inspect
      to_s
    end

    private

    def dispatch
      dbg { "#{self.class}#dispatch starts timer_id=#{timer_id}, interval=#{interval}" }

      task = Util.create_task do
        dbg { "#{self.class}#dispatch async starts timer_id=#{timer_id}, interval=#{interval}" }
        Libvirt::event_invoke_timeout_callback(timer_id, opaque)
        dbg { "#{self.class}#dispatch async async ends timer_id=#{timer_id}, interval=#{interval}" }
      end

      dbg { "#{self.class}#dispatch invokes fiber=0x#{task.fiber.object_id.to_s(16)} timer_id=#{timer_id}, interval=#{interval}" }
      task.run

      dbg { "#{self.class}#dispatch ends timer_id=#{timer_id}, interval=#{interval}" }
    end

    def wait_timer(timeout)
      begin
        @monitor.wait(timeout)
        false
      rescue Monitor::Cancelled => e
        dbg { "#{self.class}#wait_timer cancelled #{e.class} #{e.message}" }
        true
      end
    end

  end
end
