module ActiveMeta
  class Attribute
    attr_accessor :attribute, :rules

    def initialize(attribute, &block)
      raise ArgumentError.new("no block given for attribute #{attribute}") unless block_given?
      @attribute = attribute
      @rules = []
      instance_eval(&block)
    end

    def apply_to_base(base)
      rules.each do |rule|
        base.class_eval(&rule) if rule.respond_to? :to_proc
      end
    end

    def register_rule(rule)
      rule.parent = self
      rules.push(rule)
    end

    def method_missing(name, *args, &block)
      register_rule(ActiveMeta::Rule.new(attribute, name, args))
    end

    def [](arg)
      rules.select{|rule| rule.rule_name.to_s == arg.to_s }.first
    end
  end
end
