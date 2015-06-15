module ActiveMeta
  module Concern
    class << self
      def new(&block)
        raise ArgumentError.new("no block given for concern}") unless block_given?
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
