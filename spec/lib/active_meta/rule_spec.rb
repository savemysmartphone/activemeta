require 'spec_helper'

describe ActiveMeta::Rule do
  it { should have_attr_accessor :attribute }
  it { should have_attr_accessor :rule_name }
  it { should have_attr_accessor :arguments }
  it { should have_attr_accessor :parent }

  it { should alias_method :name, :rule_name }
  it { should alias_method :args, :arguments }

  context 'instance methods' do
    context '#initialize' do
    end

    context '#opts' do
    end
  end
end
