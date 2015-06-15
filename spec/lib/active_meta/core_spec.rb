require 'spec_helper'

describe ActiveMeta::Core do
  context 'class methods' do
    let :base_subject do
      Module.new do
        extend ActiveMeta::Core
      end
    end

    context '#included' do
      let(:base_subject) do
        Module.new do
          extend ActiveMeta::Core
        end
      end

      let(:base_class) do
        foo = base_subject
        Class.new do
          include foo
        end
      end

      it 'should add a #meta class method to the base class' do
        base_class.new.meta.should == base_subject
      end

      it 'should add a .meta class method to the base class' do
        base_class.meta.should == base_subject
      end
    end

    context '#attribute' do
      it 'should raise an ArgumentError when no block is passed' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        lambda{ base_subject.attribute(attr_name) }.should raise_error(ArgumentError)
      end

      it 'should create a new ActiveMeta::Attribute and pass it its block' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        ActiveMeta::Attribute.any_instance.stub(:instance_eval).and_call_original
        base_subject.attributes[attr_name].should be_nil
        base_subject.attribute(attr_name){}
        base_subject.attributes[attr_name].should have_received(:instance_eval)
      end

      it 'should call #overload on an existing ActiveMeta::Attribute and pass it its block' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        ActiveMeta::Attribute.any_instance.stub(:overload).and_call_original
        ActiveMeta::Attribute.any_instance.stub(:instance_eval).and_call_original
        base_subject.attributes[attr_name].should be_nil
        base_subject.attribute(attr_name){}
        base_subject.attributes[attr_name].should have_received(:instance_eval)
        base_subject.attributes[attr_name].should_not be_nil
        base_subject.attribute(attr_name){}
        base_subject.attributes[attr_name].should have_received(:overload)
      end
    end

    context '#attributes' do
      it 'should return this metaclass\'s attributes or empty hash' do
        attr_name = 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join
        base_subject.attribute(attr_name){}
        base_subject.attributes[attr_name].should_not be_nil
        base_subject.instance_eval{ @attributes = nil }
        base_subject.attributes.should == {}
      end
    end

    context '#rules' do
      it 'should return all attributes rules' do
        attr_names = 1.upto(4).map{ 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join }
        attr_names.each do |attr_name|
          base_subject.attribute(attr_name){}
          base_subject.attributes[attr_name].rules = attr_names.map do |rule_name|
            ActiveMeta::Rule.new(attr_name, rule_name)
          end
        end
        base_subject.rules.length.should == 16
        base_subject.rules.map(&:rule_name).uniq.should == attr_names
      end
    end

    context '#[]' do
      it 'should search rules with the same names as the passed arguments' do
        attr_names = 1.upto(4).map{ 1.upto(32).map{ ('a'..'z').to_a[rand * 26] }.join }
        attr_names.each do |attr_name|
          base_subject.attribute(attr_name){}
          base_subject.attributes[attr_name].rules = attr_names.map do |rule_name|
            ActiveMeta::Rule.new(attr_name, rule_name)
          end
        end
        attr_names.each do |attr_name|
          base_subject[attr_name].length.should == 4
          base_subject[attr_name.to_sym].length.should == 4
        end
        2.upto(4) do |x|
          attr_names.each_slice(x) do |attr_name_x|
            base_subject[*attr_name_x].length.should == attr_name_x.length * 4
            base_subject[*attr_name_x.map(&:to_sym)].length.should == attr_name_x.length * 4
          end
        end
      end
    end
  end
end
