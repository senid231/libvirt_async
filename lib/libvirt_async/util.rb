module LibvirtAsync
  module Util

    def create_task(parent = nil, &block)
      parent = Async::Task.current? if parent == :current
      Async::Task.new(Async::Task.current.reactor, parent, &block)
    end

    module_function :create_task

  end
end
