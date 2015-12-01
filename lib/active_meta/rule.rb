module ActiveMeta
  class Rule
    attr_accessor :attribute, :rule_name, :arguments, :parent, :contexts

    alias_method :name, :rule_name
    alias_method :args, :arguments

    def initialize(attribute, rule_name, *arguments)
      unless /\A[a-z_]+\z/ =~ attribute
        raise ArgumentError, "invalid attribute #{attribute}"
      end
      unless /\A[a-z_]+\z/ =~ rule_name
        raise ArgumentError, "invalid rule_name for attribute #{attribute}"
      end
      @attribute = attribute
      @rule_name = rule_name
      @arguments = arguments || []
    end

    def metaclass
      parent.metaclass
    end

    def opts
      Hash.try_convert(arguments.last) || {}
    end

    def validates_context?
      @validates_context ||= begin
        if contexts && !contexts.empty?
          context_classes = contexts.map { |context| ActiveMeta::Contexts.const_get(context) }
          context_classes.all? { |ctx| ctx.valid_for_rule?(self) }
        else
          true
        end
      end
    end
  end
end
