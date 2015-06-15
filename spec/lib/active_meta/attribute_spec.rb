require 'spec_helper'

describe ActiveMeta::Attribute do
  it { should have_attr_accessor :attribute }
  it { should have_attr_accessor :rules }
  it { should have_attr_accessor :parent }

  context 'instance methods' do
    let(:base_subject){ subject.new('t'){} }

    context '#initialize' do
      it 'should raise an ArgumentError when no attribute is passed' do
        lambda{ subject.new }.should raise_error ArgumentError
      end

      it 'should raise an ArgumentError when no block is passed' do
        lambda{ subject.new('t') }.should raise_error ArgumentError
      end

      it 'should store `attribute` as @attribute' do
        attribute = 'test_attribute'
        subject.new(attribute){}.attribute.should == attribute
      end

      it 'should prepare an array of @rules' do
        subject.new('t'){}.rules.should == []
      end

      it 'should `instance_eval` its passed block' do
        ActiveMeta::Attribute.any_instance.stub(:instance_eval)
        subject.new('t'){}.should have_received(:instance_eval)
      end
    end

    context '#apply_to_base' do
      it 'should `class_eval` all rules on the base class' do
        test_rule_class = Class.new(ActiveMeta::Rule) do
          def to_proc; @to_proc ||= Proc.new{ args.last }; end
        end
        test_rules = 0.upto(4).map do |x|
          rule = test_rule_class.new('test_apply', 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join, x)
          base_subject.register_rule(rule)
          rule
        end

        test_class = Class.new do
          class_variable_set(:@@blocks, [])
          def self.blocks; class_variable_get(:@@blocks); end
          def self.class_eval(&block); class_variable_set(:@@blocks, class_variable_get(:@@blocks) << block); end
        end
        base_subject.apply_to_base(test_class)
        test_class.blocks.should == base_subject.rules.select(&:to_proc).map(&:to_proc)
        test_class.blocks.map(&:call).should == [0,1,2,3,4]
      end
    end

    context '#overload' do
      it 'should raise an ArgumentError when no block is passed' do
        lambda{ base_subject.overload() }.should raise_error ArgumentError
      end

      it 'should `instance_eval` its passed block' do
        base_subject.stub(:instance_eval)
        base_subject.overload(){}
        base_subject.should have_received(:instance_eval)
      end
    end

    context '#register_rule' do
      it 'should raise an ArgumentError when non-Rule object is passed' do
        lambda{ base_subject.register_rule([]) }.should raise_error ArgumentError
      end

      it 'should set itself as the passed rule\'s `parent`' do
        new_rule = ActiveMeta::Rule.new('t', 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join)
        base_subject.register_rule(new_rule)
        new_rule.parent.should == base_subject
      end

      it 'should push the passed rule to its @rules' do
        new_rule = ActiveMeta::Rule.new('t', 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join)
        base_subject.rules.last.should_not == new_rule
        base_subject.register_rule(new_rule)
        base_subject.rules.last.should == new_rule
      end
    end

    context '#[]' do
      it 'should search a rule with the same name as the passed argument' do
        test_rule = ActiveMeta::Rule.new('t', 'existing_rule')
        base_subject.register_rule(test_rule)
        base_subject[:existing_rule].should == test_rule
        base_subject['existing_rule'].should == test_rule
      end

      it 'should return nil if no matching rule is set on this attribute' do
        base_subject[:inexisting_rule].should be_nil
      end
    end
  end
end
