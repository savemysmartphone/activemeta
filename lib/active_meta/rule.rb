module ActiveMeta
  class Rule
    attr_accessor :attribute, :rule_name, :arguments, :parent

    alias_method :name, :rule_name
    alias_method :args, :arguments

    def initialize(attribute, rule_name, *arguments)
      unless /^[a-z_]+$/ =~ attribute
        raise ArgumentError, "invalide attribute #{attribute}"
      end
      unless /^[a-z_]+$/ =~ rule_name
        raise ArgumentError, "invalide rule_name for attribute #{attribute}"
      end
      @attribute = attribute
      @rule_name = rule_name
      @arguments = arguments || []
    end

    def opts
      arguments.last && arguments.last.is_a?(Hash) ? arguments.last : {}
    end
  end
end
