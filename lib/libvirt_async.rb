# frozen_string_literal: true

require 'logger'
require 'libvirt_async/version'
require 'libvirt_async/error'
require 'libvirt_async/log_formatter'
require 'libvirt_async/implementations'
require 'libvirt_async/stream_read'

module LibvirtAsync
  def register_implementations!
    return false unless @implementations.nil?

    @implementations = Implementations.new
    @implementations.start
    true
  end

  module_function :register_implementations!

  def unregister_implementations!
    return false if @implementations.nil?
    @implementations.stop
    @implementations = nil
    true
  end

  module_function :unregister_implementations!

  def logger=(value)
    @logger = value
  end

  module_function :logger=

  def logger
    @logger
  end

  module_function :logger

  def build_logger(io, formatter: LogFormatter.new, progname: nil, level: :info, datetime_format: nil)
    formatter&.datetime_format = datetime_format unless datetime_format.nil?
    ::Logger.new(io, formatter: formatter, progname: progname, level: level)
  end

  module_function :build_logger

  def use_logger!(io = STDOUT, options = {})
    self.logger = build_logger(io, options)
  end

  module_function :use_logger!

  def start_debug_logging!(timeout = 2)
    LibvirtAsync.logger.debug { "scheduling debug logging!" }
    @debug_task = Util.create_task do
      LibvirtAsync.logger.debug { "starting debug logging!" }
      begin
        while true do
          raise Error, 'implementations not registered' if @implementations.nil?
          @implementations.print_debug_info
          Async::Task.current.reactor.sleep timeout
        end
      rescue Error => e
        LibvirtAsync.logger.debug { "stopping debug logging! #{e.message}" }
      end
    end
    Async::Task.current.reactor << @debug_task.fiber
  end

  module_function :start_debug_logging!

  def stop_debug_logging!
    @debug_task&.stop(true)
    @debug_task = nil
  end

  module_function :stop_debug_logging!
end
