module ActiveMeta
  class Attribute
    attr_accessor :attribute, :rules, :parent

    def initialize(attribute, &block)
      @attribute = attribute
      @rules = []
      instance_eval(&block)
    end

    def apply_to_base(base)
      rules.select(&:validates_context?).each do |rule|
        base.class_eval(&rule) if rule.respond_to? :to_proc
      end
    end

    def context(context_name = nil, &block)
      raise ArgumentError, 'no block given for context' unless block_given?
      @context_chain ||= []
      @context_chain.push(context_name)
      instance_eval(&block)
      @context_chain = nil
    end

    def metaclass
      parent
    end

    def overload(&block)
      instance_eval(&block)
    end

    def register_rule(rule)
      unless rule.is_a? ActiveMeta::Rule
        raise ArgumentError, "no rule given for attribute #{@attribute}"
      end
      # rule.attribute = self.attribute
      rule.contexts = @context_chain
      rule.parent = self
      rules.push(rule)
    end

    def [](arg)
      rules.select(&:validates_context?).find{|rule| rule.rule_name.to_s == arg.to_s }
    end

  end
end
