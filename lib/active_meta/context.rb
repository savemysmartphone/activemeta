module ActiveMeta
  module Context
    class << self
      def new(&block)
        raise ArgumentError, 'no block given for context' unless block_given?
        Module.new do
          @eval_block = block
          class << self
            def valid_for_rule?(rule)
              @eval_block.call(rule)
            end
          end
        end
      end
    end
  end
end
