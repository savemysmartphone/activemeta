module ActiveMeta
  class Rule
    attr_accessor :attribute, :rule_name, :arguments

    alias_method :name, :rule_name
    alias_method :args, :arguments

    def initialize(attribute, rule_name, *arguments)
      @attribute = attribute
      @rule_name = rule_name.to_s.underscore.gsub(/ /,'_')
      @arguments = arguments || []
    end

    def opts
      args.last
    end

    def to_hash
      nil
    end
  end
end
