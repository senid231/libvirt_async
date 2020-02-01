# frozen_string_literal: true

require 'active_support/concern'

module LibvirtAsync
  module WithDbg
    extend ActiveSupport::Concern

    class_methods do
      def dbg(progname = nil, &block)
        LibvirtAsync.logger&.debug(progname || "0x#{object_id.to_s(16)}", &block)
      end
    end

    private

    def dbg(progname = nil, &block)
      LibvirtAsync.logger&.debug(progname || "0x#{object_id.to_s(16)}", &block)
    end
  end
end
