module ActiveMeta
  module Core
    def included(base)
      # Is this javascript or what?
      this = self
      base.class_eval do
        define_method :meta do
          this
        end

        # Thanks _why for this trick!
        (class << self; self; end).instance_eval do
          define_method :meta do
            this
          end
        end

        meta.attributes.each do |_, v|
          v.apply_to_base(self)
        end

        meta.rules.map(&:class).uniq.each do |rule_class|
          class_eval(&rule_class.to_proc) if rule_class.respond_to? :to_proc
        end
      end
    end

    def attribute(attribute, &block)
      @attributes ||= {}
      if @attributes[attribute]
        @attributes[attribute].overload(&block)
      else
        @attributes[attribute] = ActiveMeta::Attribute.new(attribute, &block)
        @attributes[attribute].parent = self
      end
      @attributes[attribute]
    end

    def attributes
      @attributes || {}
    end

    def rules
      @attributes.map(&:last).flat_map(&:rules)
    end

    def [](*args)
      args = args.map(&:to_s)
      rules.select { |rule| args.include? rule.rule_name.to_s }
    end
  end
end
