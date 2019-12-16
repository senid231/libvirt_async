require 'libvirt_async/version'
require 'libvirt_async/error'
require 'libvirt_async/log_formatter'
require 'libvirt_async/implementations'

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

  def build_logger(io, formatter: nil, progname: nil, level: nil, datetime_format: nil)
    logger = Logger.new(io, formatter: formatter, progname: progname, level: level)
    logger.level = level unless level.nil?
    logger.formatter = formatter || LogFormatter.new
    logger.formatter.datetime_format = datetime_format unless datetime_format.nil?
    logger
  end

  module_function :build_logger

  def use_logger!(io = STDOUT, options = {})
    self.logger = build_logger(io, options)
  end

  module_function :use_logger!
end
