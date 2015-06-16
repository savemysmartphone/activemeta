require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

ENV['RAILS_ENV'] ||= 'test'

Bundler.require

require 'active_meta'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.mock_with(:rspec)   { |c| c.syntax = :should }
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
  match do |object_instance|
    object_instance.method_defined?(field) &&
      object_instance.method_defined?("#{field}=")
  end

  failure_message do |object_instance|
    "expected attr_accessor for #{field} on #{object_instance}"
  end

  failure_message_when_negated do |object_instance|
    "expected attr_accessor for #{field} not to be defined on #{object_instance}"
  end

  description do
    "have attr_accessor :#{field}"
  end
end

RSpec::Matchers.define :alias_its_method do |*fields|
  match do |object_instance|
    object_instance.instance_method(fields[0]) == object_instance.instance_method(fields[1])
  end

  failure_message do |object_instance|
    "expected alias for :#{fields[0]} from :#{fields[1]} to be defined on #{object_instance}"
  end

  failure_message_when_negated do |object_instance|
    "expected alias for :#{fields[0]} from :#{fields[1]} to not be defined on #{object_instance}"
  end

  description do
    "alias its method :#{fields[0]} to :#{fields[1]}"
  end
end


module RSpec::Core::MemoizedHelpers
  def subject
    __memoized.fetch(:subject) do
      __memoized[:subject] = begin
        described = described_class || self.class.metadata.fetch(:description_args).first
#        Class === described ? described.new : described
      end
    end
  end
end
