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

        meta.attributes.each do |k,v|
          v.apply_to_base(self)
        end

        meta.attributes.map(&:last).flat_map(&:rules).map(&:class).uniq.each do |rule_class|
          self.class_eval(&rule_class.to_proc) if rule_class.respond_to? :to_proc
        end
      end
    end

    def [](*args)
      args = args.map(&:to_s)
      rules.select{|rule| args.include? rule.rule_name.to_s }
    end

    def attribute(attribute, &block)
      raise ArgumentError.new('no block given') unless block_given?
      @attributes ||= {}
      if @attributes[attribute].present?
        @attributes[attribute].overload(&block)
      else
        @attributes[attribute] = ActiveMeta::Attribute.new(attribute, &block) #FIXME: Merge, not assign
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
  end
end

