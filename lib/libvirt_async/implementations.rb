require 'async'
require 'libvirt_async/with_dbg'
require 'libvirt_async/util'
require 'libvirt_async/handle'
require 'libvirt_async/timer'

module LibvirtAsync
  class Implementations
    include WithDbg

    def initialize
      dbg { "#{self.class}#initialize" }

      default_variables
    end

    def start
      dbg { "#{self.class}#start" }

      register_implementations
    end

    def stop
      dbg { "#{self.class}#stop" }

      @handles.each(&:unregister)
      @timers.each(&:unregister)

      default_variables
    end

    def print_debug_info
      str = [
          "#{self.class}:0x#{object_id.to_s(16)}",
          "handles = [",
          @handles.map(&:to_s).join("\n"),
          "]",
          "timers = [",
          @timers.map(&:to_s).join("\n"),
          "]"
      ].join("\n")
      LibvirtAsync.logger&.debug { str }
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} handles=#{@handles} timers=#{@timers}>"
    end

    def inspect
      to_s
    end

    private

    def default_variables
      @next_handle_id = 1
      @next_timer_id = 1
      @handles = []
      @timers = []
    end

    def register_implementations
      dbg { "#{self.class}#register_implementations" }

      Libvirt::event_register_impl(
          method(:add_handle).to_proc,
          method(:update_handle).to_proc,
          method(:remove_handle).to_proc,
          method(:add_timer).to_proc,
          method(:update_timer).to_proc,
          method(:remove_timer).to_proc
      )
    end

    def add_handle(fd, events, opaque)
      # add a handle to be tracked by this object.  The application is
      # expected to maintain a list of internal handle IDs (integers); this
      # callback *must* return the current handle_id.  This handle_id is used
      # both by libvirt to identify the handle (during an update or remove
      # callback), and is also passed by the application into libvirt when
      # dispatching an event.  The application *must* also store the opaque
      # data given by libvirt, and return it back to libvirt later
      # (see remove_handle)
      dbg { "#{self.class}#add_handle starts fd=#{fd}, events=#{events}" }

      @next_handle_id += 1
      handle_id = @next_handle_id
      handle = LibvirtAsync::Handle.new(handle_id, fd, events, opaque)
      @handles << handle
      handle.register

      dbg { "#{self.class}#add_handle ends fd=#{fd}, events=#{events}" }
      handle_id
    end

    def update_handle(handle_id, events)
      # update a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and the new events.  It
      # is our responsibility to find the correct handle and update the events
      # it cares about
      dbg { "#{self.class}#update_handle starts handle_id=#{handle_id}, events=#{events}" }

      handle = @handles.detect { |h| h.handle_id == handle_id }
      handle.events = events
      handle.unregister
      handle.register

      dbg { "#{self.class}#update_handle ends handle_id=#{handle_id}, events=#{events}" }
      nil
    end

    def remove_handle(handle_id)
      # remove a previously registered handle.  Libvirt tells us the handle_id
      # (which was returned to libvirt via add_handle), and it is our
      # responsibility to "forget" the handle.  We must return the opaque data
      # that libvirt handed us in "add_handle", otherwise we will leak memory
      dbg { "#{self.class}#remove_handle starts handle_id=#{handle_id}" }

      idx = @handles.index { |h| h.handle_id == handle_id }
      handle = @handles.delete_at(idx)
      handle.unregister

      dbg { "#{self.class}#remove_handle starts handle_id=#{handle_id}" }
      handle.opaque
    end

    def add_timer(interval, opaque)
      # add a timeout to be tracked by this object.  The application is
      # expected to maintain a list of internal timer IDs (integers); this
      # callback *must* return the current timer_id.  This timer_id is used
      # both by libvirt to identify the timeout (during an update or remove
      # callback), and is also passed by the application into libvirt when
      # dispatching an event.  The application *must* also store the opaque
      # data given by libvirt, and return it back to libvirt later
      # (see remove_timer)
      dbg { "#{self.class}#add_timer starts interval=#{interval}" }

      @next_timer_id += 1
      timer_id = @next_timer_id
      timer = LibvirtAsync::Timer.new(timer_id, interval, opaque)
      @timers << timer
      timer.register

      dbg { "#{self.class}#add_timer ends interval=#{interval}" }
      timer_id
    end

    def update_timer(timer_id, interval)
      # update a previously registered timer.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and the new interval.  It
      # is our responsibility to find the correct timer and update the timers
      # it cares about
      dbg { "#{self.class}#update_timer starts timer_id=#{timer_id}, interval=#{interval}" }

      timer = @timers.detect { |t| t.timer_id == timer_id }
      dbg { "#{self.class}#update_timer updating timer_id=#{timer.timer_id}" }
      timer.interval = interval
      timer.unregister
      timer.register

      dbg { "#{self.class}#update_timer ends timer_id=#{timer_id}, interval=#{interval}" }
      nil
    end

    def remove_timer(timer_id)
      # remove a previously registered timeout.  Libvirt tells us the timer_id
      # (which was returned to libvirt via add_timer), and it is our
      # responsibility to "forget" the timer.  We must return the opaque data
      # that libvirt handed us in "add_timer", otherwise we will leak memory
      dbg { "#{self.class}#remove_timer starts timer_id=#{timer_id}" }

      idx = @timers.index { |t| t.timer_id == timer_id }
      timer = @timers.delete_at(idx)
      timer.unregister

      dbg { "#{self.class}#remove_timer ends timer_id=#{timer_id}" }
      timer.opaque
    end
  end
end
