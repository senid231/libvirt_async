module LibvirtAsync
  class Handle
    # Represents an event handle (usually a file descriptor).  When an event
    # happens to the handle, we dispatch the event to libvirt via
    # Libvirt::event_invoke_handle_callback (feeding it the handle_id we returned
    # from add_handle, the file descriptor, the new events, and the opaque
    # data that libvirt gave us earlier).

    class Monitor < Async::Wrapper
      def close
        cancel_monitor
      end

      def readiness
        monitor&.readiness
      end

      def to_s
        "#<#{self.class}:0x#{object_id.to_s(16)} readable=#{@readable&.object_id&.to_s(16)} writable=#{@writable&.object_id&.to_s(16)} alive=#{@monitor && !@monitor.closed?}>"
      end

      def inspect
        to_s
      end
    end

    include WithDbg

    attr_reader :handle_id, :fd, :opaque, :monitor
    attr_accessor :events

    def initialize(handle_id, fd, events, opaque)
      dbg { "#{self.class}#initialize handle_id=#{handle_id}, fd=#{fd}, events=#{events}" }

      @handle_id = handle_id
      @fd = fd
      @events = events
      @opaque = opaque
      @monitor = nil
    end

    def register
      dbg { "#{self.class}#register handle_id=#{handle_id}, fd=#{fd}" }

      if (events & Libvirt::EVENT_HANDLE_ERROR) != 0
        dbg { "#{self.class}#register skip EVENT_HANDLE_ERROR handle_id=#{handle_id}, fd=#{fd}" }
      end
      if (events & Libvirt::EVENT_HANDLE_HANGUP) != 0
        dbg { "#{self.class}#register skip EVENT_HANDLE_HANGUP handle_id=#{handle_id}, fd=#{fd}" }
      end

      interest = events_to_interest(events)
      dbg { "#{self.class}#register parse handle_id=#{handle_id}, fd=#{fd}, events=#{events}, interest=#{interest}" }

      if interest.nil?
        dbg { "#{self.class}#register no interest handle_id=#{handle_id}, fd=#{fd}" }
        return
      end

      task = Util.create_task do
        dbg { "#{self.class}#register_handle Async start handle_id=#{handle_id}, fd=#{fd}" }
        io_mode = interest_to_io_mode(interest)

        io = IO.new(fd, io_mode, autoclose: false)
        @monitor = Monitor.new(io)

        while @monitor.readiness == nil
          cancelled = wait_io(interest)

          if cancelled
            dbg { "#{self.class}#register_handle async cancel handle_id=#{handle_id}, fd=#{fd}" }
            break
          end

          dbg { "#{self.class}#register_handle async resumes readiness=#{@monitor.readiness}, handle_id=#{handle_id}, fd=#{fd}" }
          events = readiness_to_events(@monitor.readiness)

          unless events.nil?
            dispatch(events)
            break
          end

          dbg { "#{self.class}#register_handle async not ready readiness=#{@monitor.readiness}, handle_id=#{handle_id}, fd=#{fd}" }
        end

      end

      dbg { "#{self.class}#register_handle invokes fiber=0x#{task.fiber.object_id.to_s(16)} handle_id=#{handle_id}, fd=#{fd}" }
      task.run
      dbg { "#{self.class}#register_handle ends handle_id=#{handle_id}, fd=#{fd}" }
    end

    def unregister
      dbg { "#{self.class}#unregister handle_id=#{handle_id}, fd=#{fd}" }

      if @monitor.nil?
        dbg { "#{self.class}#unregister already unregistered handle_id=#{handle_id}, fd=#{fd}" }
        return
      end

      @monitor.close
      @monitor = nil
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} handle_id=#{handle_id} fd=#{fd} events=#{events} monitor=#{monitor}>"
    end

    def inspect
      to_s
    end

    private

    def dispatch(events)
      dbg { "#{self.class}#dispatch starts handle_id=#{handle_id}, events=#{events}, fd=#{fd}" }

      task = Util.create_task do
        dbg { "#{self.class}#dispatch async starts handle_id=#{handle_id} events=#{events}, fd=#{fd}" }
        Libvirt::event_invoke_handle_callback(handle_id, fd, events, opaque)
        dbg { "#{self.class}#dispatch async ends handle_id=#{handle_id} received_events=#{events}, fd=#{fd}" }
      end
      dbg { "#{self.class}#dispatch invokes fiber=0x#{task.fiber.object_id.to_s(16)} handle_id=#{handle_id}, events=#{events}, fd=#{fd}" }
      task.run

      dbg { "#{self.class}#dispatch ends handle_id=#{handle_id}, events=#{events}, fd=#{fd}" }
    end

    def wait_io(interest)
      meth = interest_to_monitor_method(interest)
      begin
        @monitor.public_send(meth)
        false
      rescue Monitor::Cancelled => e
        dbg { "#{self.class}#wait_io cancelled #{e.class} #{e.message}" }
        true
      end
    end

    def interest_to_monitor_method(interest)
      case interest
      when :r
        :wait_readable
      when :w
        :wait_writable
      when :rw
        :wait_any
      else
        raise ArgumentError, "invalid interest #{interest}"
      end
    end

    def events_to_interest(events)
      readable = (events & Libvirt::EVENT_HANDLE_READABLE) != 0
      writable = (events & Libvirt::EVENT_HANDLE_WRITABLE) != 0
      if readable && writable
        :rw
      elsif readable
        :r
      elsif writable
        :w
      else
        nil
      end
    end

    def interest_to_io_mode(interest)
      case interest
      when :rw
        'a+'
      when :r
        'r'
      when :w
        'w'
      else
        raise ArgumentError, "invalid interest #{interest}"
      end
    end

    def readiness_to_events(readiness)
      case readiness&.to_sym
      when :rw
        Libvirt::EVENT_HANDLE_READABLE | Libvirt::EVENT_HANDLE_WRITABLE
      when :r
        Libvirt::EVENT_HANDLE_READABLE
      when :w
        Libvirt::EVENT_HANDLE_WRITABLE
      else
        nil
      end
    end
  end
end
