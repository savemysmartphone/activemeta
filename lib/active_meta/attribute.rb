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

    # def method_missing(name, *args, &block)
    #   register_rule(ActiveMeta::Rule.new(attribute, name, args))
    # end

    def overload(&block)
      instance_eval(&block)
    end

    def register_rule(rule)
      raise ArgumentError.new("no rule given for attribute #{@attribute}") unless rule.is_a? ActiveMeta::Rule
      #rule.attribute = self.attribute
      rule.parent = self
      rules.push(rule)
    end

    def [](arg)
      rules.select{|rule| rule.rule_name.to_s == arg.to_s }.first
    end
  end
end
