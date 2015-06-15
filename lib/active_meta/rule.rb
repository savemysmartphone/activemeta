module ActiveMeta
  class Rule
    attr_accessor :attribute, :rule_name, :arguments, :parent

    alias_method :name, :rule_name
    alias_method :args, :arguments

    def initialize(attribute, rule_name, *arguments)
      raise ArgumentError.new("invalide attribute #{attribute}") unless /^[a-z_]+$/ =~ attribute
      raise ArgumentError.new("invalide rule_name for attribute #{attribute}") unless /^[a-z_]+$/ =~ rule_name
      @attribute = attribute
      @rule_name = rule_name.to_s.gsub(/.?[A-Z]/){|x| "#{"#{x[0]}_" if x[1]}#{x[-1].downcase}" }.downcase
      @arguments = arguments || []
    end

    def opts
      arguments.last || {}
    end
  end
end
