#ActiveMeta
ActiveMeta is a new way to write Rails models which prioritizes properties and behaviours in reusable `Rule`s.

The main purpose of ActiveMeta is to store informations about your ActiveRecord models. The main question it tries to answer is "How do I know which attributes of my models are strings? Which attributes are ActiveRecord relations? Which attributes should validate uniqueness?".

By themselves, these questions can be answered with [help](http://stackoverflow.com/questions/1257658/rails-is-there-a-way-to-check-the-fields-datatype) [from](http://stackoverflow.com/questions/259529/how-can-i-find-a-models-relationships) [StackOverflow](http://stackoverflow.com/questions/4051864/get-validations-from-model). However, all of them will be accessed in a different way and you won't have a unique way to easily retrieve a model's properties, should you need use them elsewhere (let's say: if you want to send them to a frontend API).

ActiveMeta is nothing more than a wrapper: it stores attributes and their rules. It is up to you to write rules according to the properties you want to store/retrieve and the behaviour you want to apply to your ActiveRecord models.

# Changelog

* First working version. (Arnaud 'red' Rouyer)


# Quick example
With the correct rules defined (in this case: `type`, `validates_presence`, `getter` and `has_many`), here is an example MetaClass.

```
module Meta::User
  extend ActiveMeta::Core

  attribute :last_name do
    type :string
    validates_presence
  end

  attribute :first_name do
    type :string
    validates_presence
  end

  attribute :age do
    type :integer
    validates_presence
  end

  attribute :full_name do
    getter do
      "#{last_name} #{first_name} (#{age} years)"
    end
  end

  attribute :orders do
    has_many
  end
end

class User < ActiveRecord::Base
  include Meta::User
end

```

Now, using `User.meta`, you can know which attributes are required for your `User` model, which attributes are expecting strings or numbers and which one is an ActiveRecord relation.

While `type` only stores information, the `validates_presence`, `getter` and `has_many` wrappers will apply themselves to your ActiveRecord model to call the proper methods. That is:

*   `validates_presence` on attributes `:age`, `:last_name` and `:first_name` will call `validates_presence_of :age, :last_name, :first_name`.
*   `getter` on attribute `:full_name` will define a `#full_name` method with the provided block.
*   `has_many` on attribute `:orders` will call `has_many :orders`.

Now, your `User` model has the behaviour you wanted, and you can use `User.meta` to get all its properties in the way you want them.

# Getting started
Three components define the core concepts of ActiveMeta: `Core`, `Rule` and `Attribute`.

## ActiveMeta::Core
The `ActiveMeta::Core` module defines the main ActiveMeta entry point: that is, the first thing
required to make your own MetaClass.

To become a MetaClass, your module needs to extend `ActiveMeta::Core`.

```
module Meta
  module User
    extend ActiveMeta::Core
  end
end
```
Under the hood, this will add five methods to your MetaClass:

-  `ActiveMeta::Core#included(base)`
   This method is the standard [Module#included](http://ruby-doc.org/core-2.1.0/Module.html#method-i-included) method. This method is tasked with 1) extending your base model with methods (`#meta` and `.meta`) to access your MetaClass and its properties, 2) apply your MetaClass rules to your base model.

-   `ActiveMeta::Core#attribute(attribute, &block)`
    This method is to be called from your MetaClass to define a new `ActiveMeta::Attribute` with a block of rules. These rules will be evaluated in the context of the newly-created attribute.

```
module Meta::User
  extend ActiveMeta::Core

  attribute :last_name do
    first_rule_for_last_name
    second_rule_for_last_name
  end

  attribute :first_name do
    first_rule_for_first_name
    second_rule_for_last_name
  end
end
```

-   `ActiveMeta::Core#attributes`
    Accessor for @attributes, a hash containing the currently defined attributes as keys and their `ActiveMeta::Attribute` as values.

```
class User < ActiveRecord::Base
  extend Meta::User
end

User.meta.attributes.keys # => [:last_name, :first_name]
User.meta.attributes.values[0] # => <ActiveMeta::Attribute @attribute=:last_name>
User.meta.attributes.values[1] # => <ActiveMeta::Attribute @attribute=:first_name>
```

-   `ActiveMeta::Core#rules`
    Accessor for all `ActiveMeta::Rule` instances pertaining to this MetaClass.

```
User.meta.rules.length # => 4
User.meta.rules[0] # => <ActiveMeta::Rule @attribute=:last_name @rule_name="first_rule_for_last_name">
User.meta.rules[3] # => <ActiveMeta::Rule @attribute=:first_name @rule_name="second_rule_for_last_name">
```

-   `ActiveMeta::Core#\[\](*args)`
    Quicker accessor to select rules depending on their name. Supports multiple arguments.

```
User.meta[:second_rule_for_last_name].length # => 1
User.meta[:second_rule_for_last_name]
# => [<ActiveMeta::Rule @attribute=:first_name @rule_name="second_rule_for_last_name">]
#
User.meta[:second_rule_for_last_name, :first_rule_for_last_name]
# => [
#  <ActiveMeta::Rule @attribute=:last_name @rule_name="first_rule_for_last_name">,
#  <ActiveMeta::Rule @attribute=:first_name @rule_name="second_rule_for_last_name">
# ]
```

## ActiveMeta::Rule
By itself, an instance of `ActiveMeta::Rule` only contains the `@attribute` for which it was defined, the `@rule_name` defined in its constructor and the `@arguments` passed to it.

It is up to you to build new classes inheriting `ActiveMeta::Rule` to suit the common properties and behaviours of your attributes.

### Storing properties
As said earlier, by default, an instance of `ActiveMeta::Rule#initialize` will store `@attribute`, `@rule_name` and `@arguments`.

This is especially useful to create "properties rules", which are rules not altering model bahaviour, but providing us with easy-to-access informations regarding their attributes.

```
class NiceAttributeRule < ActiveMeta::Rule # Rule called with 'nice_attribute(arguments)'
  def is_this_attribute_nice?
    @arguments.last
  end
end

class UpdatableRule < ActiveMeta::Rule # Rule called with 'updatable(arguments)'
  def updatable_by?(role)
    @arguments.last[:on] == role
  end
end

module Meta::User # MetaClass definition
  extend ActiveMeta::Core

  attribute :last_name do
    nice_attribute true
    updatable by: :admin
  end

  attribute :first_name do
    nice_attribute false
    updatable by: :admin
  end

  attribute :age do
    nice_attribute true
    updatable by: :nobody
  end
end

class User < ActiveRecord::Base
  include Meta::User # include our MetaClass
end

User.meta.attributes[:last_name].rules.first.class.name  # => NiceAttributeRule
User.meta.attributes[:last_name].rules.first.is_this_attribute_nice? # => true

User.meta.attributes[:first_name].rules.first.class.name  # => NiceAttributeRule
User.meta.attributes[:first_name].rules.first.is_this_attribute_nice? # => false

User.meta[:nice_attribute].select(&:is_this_attribute_nice?).map(&:attribute) # => ['last_name']
User.meta[:updatable].select{|x| x.updatable_by?(:admin) }.map(&:attribute) # => ['last_name', 'first_name']

```

### Altering your base class
After defining your model properties, you will want to define your model's behaviour. Rules can be built for this on two levels: attribute-level and class-level.

#### Altering your base class for each attribute

If your rule defines a `#to_proc` (instance) method, the resulting `Proc` will be applied (using [Module#class_eval](http://ruby-doc.org/core-2.2.0/Module.html#method-i-class_eval)) to your ActiveRecord model for each attribute which called the rule.

```
class ValidatesUniquenessRule < ActiveMeta::Rule
  def to_proc
    binded_attribute = attribute
    Proc.new do
      validates_uniqueness_of binded_attribute
    end
  end
end

class HasManyRule < ActiveMeta::Rule
  def to_proc
    binded_attribute = attribute
    Proc.new do
      has_many binded_attribute.to_sym
    end
  end
end

module Meta::User
  attribute :email do
    validates_uniqueness
  end

  attribute :phone_number do
    validates_uniqueness
  end

  attribute :social_networks do
    has_many
  end
end

```

In the block before, `ValidatesUniquenessRule#to_proc` will be called twice (once for :email, then for :phone_number) and `HasManyRule#to_proc` will be called once for :social_networks.

This is useful for `Proc`s defining behaviour specifics to one attribute.

#### Altering your base class for multiple attributes

If your rule defines a `.to_proc` (class) method, the resulting `Proc` will be applied (using [Module#class_eval](http://ruby-doc.org/core-2.2.0/Module.html#method-i-class_eval)) to your ActiveRecord model ONCE, no matter how many attributes you defined it for.

This is useful to avoid calling the same code multiple times when no references to attributes is needed.

```
class UpdatableRule < ActiveMeta::Rule
  class << self
    def to_proc
      Proc.new do
        class << self
          def updatable_fields
            self.meta[:updatable].map(&:attribute)
          end
        end
      end
    end
  end
end

module Meta::User
  attribute ):id do
    not_updatable
  end

  attribute :last_name do
    updatable
  end

  attribute :first_name do
    updatable
  end
end

User.updatable_fields # => [:last_name, :first_name]
```

In the block before, `UpdatableRule.to_proc` will be called once.

This is useful for `Proc`s defining behaviour not specific to one attribute and partaining to multiple attributes.


## ActiveMeta::Attribute
An attribute defines a field on which rules will apply. This can be either an attribute from the ActiveRecord model, or a virtual attribute which will be fed/will feed existing ActiveRecord attributes.

```
module Meta::User
  extend ActiveMeta::Core

  attribute :last_name do
    do_not_export_json
  end

  attribute :first_name do
    do_not_export_json
  end

  attribute :full_name do
    always_Export_json

    getter do
      "#{last_name}, #{first_name}"
    end
  end
end
```

-   `ActiveMeta::Attribute#initialize(attribute, &block)`
    Attributes are built exactly as defined in the MetaClass: calling `attribute(:last_name){ rule_block }` will call `ActiveMeta::Attribute.new(:last_name){ rule_block }`. The passed block is called straight with `instance_eval` to evaluate all rules with the current attribute as context.

-   `ActiveMeta::Attribute#method_missing(name, *args, &block)`
    If no rule factories methods are defined within the context of `ActiveMeta::Attribute`, a call to an inexisting method will still create a rule WITH NO CONFIGURATION, only holding its own name (the method name) and the passed arguments as `@arguments`.

```
module Meta::User
  extend ActiveMeta::Core

  attribute :foo do
    existing_rule
    inexisting_rule with: :arguments
  end
end

User.meta.rules
# => [
#    <ExistingActiveMetaRule @attribute=:foo @rule_name="an_existing_rule">,
#   <ActiveMeta::Rule @attribute=:foo @rule_name=inexisting_rule @arguments={with: :arguments}>
# ]
```

-   `ActiveMeta::Attribute#register_rule(rule)`
    Factory to register an `ActiveMeta::Rule` binded to the current `ActiveMeta::Attribute`. A rule SHOULD NOT be added manually to the internal `@rules` array (which holds the attribute rules) because `register_rule` sets up the rule's `@parent` to itself.

```
  User.meta.attributes[:foo] # => <ActiveMeta::Attribute @attribute=:foo>
  User.meta.attributes[:foo].rules.map(&:parent).uniq #=> [<ActiveMeta::Attribute @attribute=:foo>]

```

-   `ActiveMeta::Attribute#\[\](arg)`
    Quick accessor to access a specific rule on an attribute (or assess its existence).

```
User.meta.attributes[:foo]['existing_rule']
# => <ActiveMeta::Rule @attribute=:foo @rule_name='existing_rule'>

User.meta.attributes[:foo]['absent_rule]
# => nil

```

-   `ActiveMeta::Attribute#apply_to_base(base)`
    Once your MetaClass has been included in your base model class, this method will be called with your base model class as an argument. This will loop on all defined rules for the current attribute. Each rule defining a `#to_proc` method will have this `Proc` evaluated in the context of your base class.

```
class MyRule < ActiveMeta::Rule
  def to_proc
    Proc.new do
      puts "__#{self}__"
    end
  end
end

module Meta::Test
  attribute :test do
    my_rule
  end
end

class User < ActiveRecord::Base
end
User.send(:include, Meta::Test)
# => __<MyRule:Class>__
```


# Going further

## ActiveMeta::Concern
A concern is a block of code (attributes and rules) that is used in multiple MetaClasses.

The block is defined by passing it to `ActiveMeta::Concern.new`. A `Module` is returned to be extended in any of your MetaClasses.

```
PhoneableConcern = ActiveMeta::Concern.new do
  attribute :phone_number do
    type :string
    validates_uniqueness
  end
end

module Meta::User
  extend PhoneableConcern
end

module Meta::Customer
  extend PhoneableConcern
end

Class User < ActiveRecord::Base
  include Meta::User
end

class Customer < ActiveRecord::Base
  include Meta::Customer
end

User.meta.attributes[:phone_number].length # => 1
Customer.meta.attributes[:phone_number].length # => 1

```
## ActiveMeta::Recipes and ActiveMeta::Concerns

These namespaces are here to include your own sets of rules and concerns depending on the library they relate to.

Ideal namespaces would be:

* `ActiveMeta::Recipes::ActiveRecord::Validations::Uniqueness` to call [.validates_uniqueness_for](http://api.rubyonrails.org/classes/ActiveRecord/Validations/ClassMethods.html#method-i-validates_uniqueness_of)



* `ActiveMeta::Concerns::ActsAsParanoid` to call [.acts_as_paranoid](https://github.com/ActsAsParanoid/acts_as_paranoid)

```
module ActiveMeta::Concerns
  ActsAsParanoid = ActiveMeta::Concern.new do
    attribute :deleted_at
      type :datetime
      acts_as_paranoid
    end
  end
end
```
