module ActiveMeta
  module Concern
    class << self
      def new(&block)
        ::Module.new do
          @eval_block = block
          class << self
            def extended(base)
              base.class_eval(&@eval_block)
            end
          end
        end
      end
    end
  end
end
