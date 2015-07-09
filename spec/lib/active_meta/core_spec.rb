require 'spec_helper'

describe ActiveMeta::Core do
  context 'class methods' do
    let :base_klass do
      Module.new do
        extend ActiveMeta::Core
      end
    end

    context '#included' do
      let(:base_rule) do
        Class.new(ActiveMeta::Rule) do
          def to_proc
            @to_proc ||= proc  do
              new_blocks = class_variable_get(:@@blocks) + [['instance']]
              class_variable_set(:@@blocks, new_blocks)
            end
          end
          def self.to_proc
            @to_proc ||= proc do
              new_blocks = class_variable_get(:@@blocks)
              new_blocks += [['class', meta.rules.map(&:rule_name)]]
              class_variable_set(:@@blocks, new_blocks)
            end
          end
        end
      end

      let(:base_klass) do
        mod = Module.new do
          extend ActiveMeta::Core
        end
        attr_names = 1.upto(4).map do
          1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        end
        attr_names.each do |attr_name|
          mod.attribute(attr_name){}
          attr_names.each do |rule_name|
            new_rule = base_rule.new(attr_name, rule_name, rule_name)
            mod.attributes[attr_name].register_rule new_rule
          end
        end
        mod
      end

      let(:base_class) do
        foo = base_klass
        Class.new do
          class_variable_set(:@@blocks, [])
          include foo
          def self.blocks; class_variable_get(:@@blocks); end
        end
      end

      it 'should add a #meta class method to the base class' do
        base_class.new.meta.should == base_klass
      end

      it 'should add a .meta class method to the base class' do
        base_class.meta.should == base_klass
      end

      it 'should apply all attributes to the base class' do
        base_class.blocks.count{|x| x.first == 'instance' }.should == 16
      end
    end

    context '#attribute' do
      it 'should raise an ArgumentError when no block is passed' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        ->{ base_klass.attribute(attr_name) }.should raise_error ArgumentError
      end

      it 'should create a new ActiveMeta::Attribute and pass it its block' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        am_attr_any = ActiveMeta::Attribute.any_instance
        am_attr_any.stub(:instance_eval).and_call_original
        base_klass.attributes[attr_name].should be_nil
        base_klass.attribute(attr_name){}
        base_klass.attributes[attr_name].should have_received(:instance_eval)
      end

      it 'should call #overload on an existing ActiveMeta::Attribute' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        am_attr_any = ActiveMeta::Attribute.any_instance
        am_attr_any.stub(:overload).and_call_original
        am_attr_any.stub(:instance_eval).and_call_original
        base_klass.attributes[attr_name].should be_nil
        base_klass.attribute(attr_name){}
        base_klass.attributes[attr_name].should have_received(:instance_eval)
        base_klass.attributes[attr_name].should_not be_nil
        base_klass.attribute(attr_name){}
        base_klass.attributes[attr_name].should have_received(:overload)
      end
    end

    context '#attributes' do
      it 'should return this metaclass\'s attributes or empty hash' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        base_klass.attribute(attr_name){}
        base_klass.attributes[attr_name].should_not be_nil
        base_klass.instance_eval{ @attributes = nil }
        base_klass.attributes.should == {}
      end
    end

    context '#rules' do
      it 'should return all attributes rules' do
        attr_names = 1.upto(4).map do
          1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        end
        attr_names.each do |attr_name|
          base_klass.attribute(attr_name){}
          base_klass.attributes[attr_name].rules = attr_names.map do |rule_name|
            ActiveMeta::Rule.new(attr_name, rule_name)
          end
        end
        base_klass.rules.length.should == 16
        base_klass.rules.map(&:rule_name).uniq.should == attr_names
      end
    end

    context '#[]' do
      it 'should search rules with the same names as the passed arguments' do
        attr_names = 1.upto(4).map do
          1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        end
        attr_names.each do |attr_name|
          base_klass.attribute(attr_name){}
          base_klass.attributes[attr_name].rules = attr_names.map do |rule_name|
            ActiveMeta::Rule.new(attr_name, rule_name)
          end
        end
        attr_names.each do |attr_name|
          base_klass[attr_name].length.should == 4
          base_klass[attr_name.to_sym].length.should == 4
        end
        2.upto(4) do |x|
          attr_names.each_slice(x) do |attr_name_x|
            results_length = attr_name_x.length * 4
            str_args = attr_name_x
            sym_args = attr_name_x.map(&:to_sym)
            base_klass[*str_args].length.should == results_length
            base_klass[*sym_args].length.should == results_length
          end
        end
      end
    end
  end
end
