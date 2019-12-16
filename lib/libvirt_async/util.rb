module LibvirtAsync
  module Util

    def create_task(&block)
      Async::Task.new(Async::Task.current.reactor, &block)
    end

    module_function :create_task

  end
end
