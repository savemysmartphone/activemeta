module ActiveMeta
  class Attribute
    attr_accessor :attribute, :rules, :parent

    def initialize(attribute, &block)
      @attribute = attribute
      @rules = []
      instance_eval(&block)
    end

    def apply_to_base(base)
      rules.each do |rule|
        base.class_eval(&rule) if rule.respond_to? :to_proc
      end
    end

    def overload(&block)
      instance_eval(&block)
    end

    def register_rule(rule)
      unless rule.is_a? ActiveMeta::Rule
        raise ArgumentError, "no rule given for attribute #{@attribute}"
      end
      # rule.attribute = self.attribute
      rule.parent = self
      rules.push(rule)
    end

    def [](arg)
      rules.find{|rule| rule.rule_name.to_s == arg.to_s }
    end
  end
end
