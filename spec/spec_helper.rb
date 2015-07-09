require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

ENV['RAILS_ENV'] ||= 'test'

Bundler.require

require 'active_meta'

RSpec.configure do |config|
  config.expect_with(:rspec) {|c| c.syntax = :should }
  config.mock_with(:rspec)   {|c| c.syntax = :should }
  config.order = 'default'
end

RSpec::Matchers.define :autoload do |subclass|
  match do |klass|
    klass.autoload? subclass
  end

  failure_message do |klass|
    "expected #{klass.name} to autoload #{subclass}"
  end

  failure_message_when_negated do |klass|
    "expected #{klass.name} not to autoload from #{subclass}"
  end
end

RSpec::Matchers.define :have_attr_accessor do |field|
  match do |klass|
    klass.method_defined?(field) &&
      klass.method_defined?("#{field}=")
  end

  failure_message do |klass|
    "expected attr_accessor for #{field} on #{klass}"
  end

  failure_message_when_negated do |klass|
    "expected attr_accessor for #{field} not to be defined on #{klass}"
  end

  description do
    "have attr_accessor :#{klass}"
  end
end

RSpec::Matchers.define :alias_its_method do |*f|
  match do |klass|
    klass.instance_method(f[0]) == klass.instance_method(f[1])
  end

  failure_message do |klass|
    "expected alias for :#{f[0]} from :#{f[1]} to be defined on #{klass}"
  end

  failure_message_when_negated do |klass|
    "expected alias for :#{f[0]} from :#{f[1]} to not be defined on #{klass}"
  end

  description do
    "alias its method :#{f[0]} to :#{f[1]}"
  end
end

module RSpec
  module Core
    module MemoizedHelpers
      def subject
        __memoized.fetch(:subject) do
          __memoized[:subject] = begin
            metadata = self.class.metadata
            described_class || metadata.fetch(:description_args).first
          end
        end
      end
    end
  end
end
