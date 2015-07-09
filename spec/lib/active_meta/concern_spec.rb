require 'spec_helper'

describe ActiveMeta::Concern do
  describe 'class methods' do
    describe '.new' do
      it 'should raise an ArgumentError when no block is passed' do
        ->{ subject.new }.should raise_error ArgumentError
      end

      it 'should return a new Module' do
        subject.new{}.should be_a_kind_of Module
      end

      context 'the returned Module' do
        let(:test_proc) do
          proc do
            def foo; bar; end

            def bar; 'foobar'; end
          end
        end
        let(:test_module){ subject.new(&test_proc) }

        it 'should contain the passed block as @eval_block' do
          test_module.instance_eval{ @eval_block }.should be_a_kind_of Proc
          test_module.instance_eval{ @eval_block }.should == test_proc
        end

        it 'should define an .extended method that takes one argument' do
          test_module.respond_to?(:extended).should == true
          test_module.method(:extended).arity.should == 1
        end

        it 'should extend a Class and call .class_eval on it' do
          test_class = Class.new do
            class << self
              def class_eval(&block)
                @called_class_eval = true
                super(&block)
              end
            end
          end.send(:extend, test_module)
          test_class.instance_variable_get(:@called_class_eval).should == true
        end

        it 'should extend a Class and apply its @eval_block to it' do
          test_class = Class.new.send(:extend, test_module)
          test_class.method_defined? :foo
          test_class.method_defined? :bar
          test_class.new.foo.should == 'foobar'
          test_class.new.bar.should == 'foobar'
        end
      end
    end
  end
end
