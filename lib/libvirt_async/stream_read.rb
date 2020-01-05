module LibvirtAsync
  class StreamRead
    # StreamRead allows to work with stream in non-block read mode.

    STATE_COMPLETED = 'completed'.freeze
    STATE_CANCELLED = 'cancelled'.freeze
    STATE_FAILED = 'failed'.freeze
    STATE_PENDING = 'pending'.freeze

    class RecvError < StandardError
    end

    include WithDbg

    attr_reader :state, :stream, :io

    # @param connection [Libvirt::Connection]
    # @param io [IO]
    # @return [LibvirtAsync::Stream]
    def initialize(connection, io)
      @connection = connection
      @io = io
      @callback = nil
      @state = STATE_PENDING
      @stream = @connection.stream(Libvirt::Stream::NONBLOCK)
    end

    # @yield asynchronously on complete or error
    # @yieldparam success [Boolean]
    # @yieldparam reason [String,NilClass]
    # @yieldparam io [IO]
    def call(&block)
      add_callback(block) if block_given?

      run
    end

    def add_callback(block)
      raise ArgumentError, 'block must be a Proc' unless @callback.is_a?(Proc)
      @callback = block
    end

    def run
      raise ArgumentError, 'block must be given' if @callback.nil?

      dbg { "#{to_s}#call event_add_callback calling" }
      @cb_opaque = stream.event_add_callback(
          Libvirt::Stream::EVENT_READABLE,
          -> (_stream, events, _opaque) { stream_callback(events) },
          self
      )
      dbg { "#{to_s}#call event_add_callback called" }

      nil
    rescue Libvirt::Error => e
      dbg { "#{to_s}#call error occurred\n<#{e.class}>: #{e.message}\n#{e.backtrace.join("\n")}" }
      @state = STATE_FAILED
      stream&.finish rescue nil
      on_error(e)
      @cb_opaque = nil
    end

    def cancel
      dbg { "#{to_s}#cancel" }
      return if stream.nil?

      @state = STATE_CANCELLED
      stream.event_remove_callback
      stream.finish
      @stream = nil
    rescue Libvirt::Error => e
      dbg { "#{to_s}#cancel error occurred\n<#{e.class}>: #{e.message}\n#{e.backtrace.join("\n")}" }
      @stream = nil
    ensure
      @cb_opaque = nil
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} @state=#{@state}>"
    end

    def inspect
      to_s
    end

    private

    def on_error(error)
      @callback.call(false, "#{error.class}: #{error.message}", io)
    end

    def on_receive(data)
      io.write(data)
    end

    def on_complete
      @callback.call(true, nil, io)
    end

    # @param events [Integer]
    def stream_callback(events)
      dbg { "#{to_s}#stream_callback events=#{events}" }
      return unless (Libvirt::Stream::EVENT_READABLE & events) != 0
      # `stream.finish` will be executed asynchronously
      # so callback will be triggered even after we complete data transfer.
      if state != STATE_PENDING
        dbg { "#{to_s}#stream_callback called for #{state} stream. Skipping." }
        return
      end

      process_read

    rescue RecvError, Libvirt::Error => e
      dbg { "#{to_s}#stream_callback error occurred\n<#{e.class}>: #{e.message}\n#{e.backtrace.join("\n")}" }
      @state = STATE_FAILED
      stream.finish rescue nil
      on_error(e)
      @cb_opaque = nil
    end

    def process_read
      code, data = stream.recv(1024)
      dbg { "#{to_s}#stream_callback recv code=#{code}, size=#{data&.size}" }

      case code
      when 0
        dbg { "#{to_s}#stream_callback finished" }
        @state = STATE_COMPLETED
        stream.finish
        on_complete
        @cb_opaque = nil
      when -1
        dbg { "#{to_s}#stream_callback code -1" }
        raise RecvError, 'error code -1 received'
      when -2
        dbg { "#{to_s}#stream_callback is not ready" }
      else
        dbg { "#{to_s}#stream_callback ready code=#{code}" }
        on_receive(data)
      end
    end

  end
end
