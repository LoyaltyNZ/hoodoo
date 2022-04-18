########################################################################
# File::    monkey.rb
# (C)::     Loyalty New Zealand 2016
#
# Purpose:: Official, reversible monkey patching.
# ----------------------------------------------------------------------
#           11-Apr-2016 (ADH): Created.
########################################################################

module Hoodoo

  # Hoodoo provides monkey patching hook points as first class citizens and
  # includes a registration, enabling and disabling mechanism through the
  # Hoodoo::Monkey class.
  #
  # You encapsulate monkey patch code inside a module. This module will be
  # used to patch one or more target other classes or modules. Usually, one
  # module will only be used to patch one other kind of class or module;
  # re-use of a patch module usually only makes sense when patching one
  # or more subclasses from a common ancestor where some, but not all of
  # the subclass types are to be patched (if you wanted to patch all of them
  # you'd just patch the base class).
  #
  # Inside your module, you write one or two sub-modules. One of these
  # patches instance methods in the target, the other patches class methods.
  # The mechanism used to patch instance or class methods is different in
  # Ruby, thus the distinct module use; it also helps keep your code clear
  # of distracting syntax and make it very obvious what kind of "thing" is
  # being replaced.
  #
  # Monkey patch methods are sent to the patch target using `prepend`, the
  # Ruby 2 mechanism which means the original overriden implementation can
  # be called via +super+, just as if you were writing a subclass.
  #
  # For examples, see method Hoodoo::Monkey::register.
  #
  # Any public method in the API can be patched, since the public API is by
  # definition public and stable. Sometimes, normally-private methods are
  # exposed for monkey patching as public methods with the name prefix of
  # "<tt>monkey_</tt>" - such methods are *NOT* intended to be called by
  # client code in general, but can be patched. It is only completely safe to
  # to patch a method in a wrapper fashion, e.g. to filter inputs or outputs;
  # thus whenever possible, always call +super+ at some point within your
  # replacement implementation. If you completely replace an implementation
  # with a custom version, you risk your code breaking even with patch level
  # changes to Hoodoo, since only the public _interface_ is guaranteed; the
  # way in which it is _implemented_ is not.
  #
  # You tell the monkey patching system about the outer container module, the
  # instance and/or class patch modules and the target entity via a call to
  # Hoodoo::Monkey::register. See this for more details. Use
  # Hoodoo::Monkey::enable to actually 'switch on' the patch and
  # Hoodoo::Monkey::disable to 'switch off' the patch again.
  #
  # The patch engine is "require'd" by Hoodoo as the very last thing in all of
  # its other inclusion steps when 'hoodoo.rb' ("everything") is included by
  # code. If individual sub-modules of Hoodoo are included by client code, it
  # will be up to them when (and if) the monkey patch engine is brought in.
  #
  # Hoodoo authors should note namespaces Hoodoo::Monkey::Patch and
  # Hoodoo::Monkey::Chaos inside which out-of-the-box Hoodoo patch code should
  # be defined. Third party patches must use their own namespaces to avoid any
  # potential for collision with future new Hoodoo patch modules.
  #
  module Monkey
    @@modules = {}

    # Register a set of monkey patch modules with Hoodoo::Monkey - see the
    # top-level Hoodoo::Monkey documentation for an introduction and some
    # high level guidelines for monkey patch code.
    #
    # _Named_ parameters are:
    #
    # +target_unit+::             The Class or Module to be patched.
    # +extension_module+::        The module that identifies the collection of
    #                             instance and/or class methods to overwrite
    #                             inside the targeted unit. This MUST define
    #                             a nested module called "InstanceExtensions"
    #                             containing method definitions that will
    #                             override same-name instance methods in the
    #                             targeted unit, or a nested module called
    #                             "ClassExtensions" to override class methods,
    #                             or both.
    #
    # For example, suppose we have this class:
    #
    #     class Foo
    #       def bar
    #         2 * 2
    #       end
    #
    #       def self.bar
    #         3 * 3
    #       end
    #     end
    #
    #     Foo.new.bar
    #     # => 4
    #     Foo.bar
    #     # => 9
    #
    # Next define modules which extend/override methods in the above class:
    #
    #    module ExtendedFoo
    #      module InstanceExtensions
    #        def bar
    #          5 * 5
    #        end
    #      end
    #
    #      module ClassExtensions
    #
    #        # Even though this module will be used to override class methods
    #        # in the target, we define the module methods with "def bar", not
    #        # "def self.bar".
    #        #
    #        def bar
    #          7 * 7
    #        end
    #      end
    #    end
    #
    # At this point, the extension is defined, but not registered with Hoodoo
    # and not yet enabled. Register it with:
    #
    #     Hoodoo::Monkey.register(
    #       target_unit:      Foo,
    #       extension_module: ExtendedFoo
    #     )
    #
    # The code is now registered so that it can be easily enabled or disabled
    # via the given +extension_module+ value:
    #
    #     Hoodoo::Monkey.enable( ExtendedFoo )
    #
    #     Foo.new.bar
    #     # => 25
    #     Foo.bar
    #     # => 49
    #
    #     Hoodoo::Monkey.disable( ExtendedFoo )
    #
    #     Foo.new.bar
    #     # => 4
    #     Foo.bar
    #     # => 9
    #
    # You can register the same extension modules for multiple target units,
    # but it can only be enabled or disabled all in one go for all targets.
    #
    def self.register( target_unit:, extension_module: )

      if extension_module.const_defined?( 'InstanceExtensions', false )
        instance_methods_module = extension_module.const_get( 'InstanceExtensions' )
      end

      if extension_module.const_defined?( 'ClassExtensions', false )
        class_methods_module = extension_module.const_get( 'ClassExtensions' )
      end

      if instance_methods_module.nil? && class_methods_module.nil?
        raise "Hoodoo::Monkey::register: You must define either an InstanceExtensions module ClassExtensions module or both inside '#{ extension_module.inspect }'"
      end

      @@modules[ extension_module ] ||= {}
      @@modules[ extension_module ][ target_unit ] =
      [
        {
          :patch_module => instance_methods_module,
          :patch_target => target_unit
        },
        {
          :patch_module => class_methods_module,
          :patch_target => target_unit.singleton_class
        }
      ]

    end

    # Enable a given monkey patch, using the extension module parameter value
    # given to a prior call to ::register (see there for more information).
    #
    # The initial patch installation is done via <tt>Module#prepend</tt>, so
    # you are able to call +super+ to invoke the original implementation from
    # the overriding implementation, as if you were writing a subclass.
    #
    # Instance and class method monkey patches should try very hard to always
    # call "super" so that an overridden/patched public API method will still
    # call back to its original implementation; the wrapper just filters
    # inputs and outputs or adds additional behaviour. This way, changes to
    # the Hoodoo implementation will not break the patch.
    #
    # Patching is global; it is not lexically scoped. Use Ruby refinements
    # manually if you want lexically scoped patches.
    #
    # _Named_ parameters are:
    #
    # +extension_module+:: A module previously passed in the same-named
    #                      parameter to ::register. The instance and/or class
    #                      methods defined therein will be applied to the
    #                      previously registered target.
    #
    # Enabling the same extension multiple times has no side effects.
    #
    def self.enable( extension_module: )
      if ( target_units_hash = @@modules[ extension_module ] ).nil?
        raise "Hoodoo::Monkey::enable: Extension module '#{ extension_module.inspect }' is not registered"
      end

      target_units_hash.each_value do | target_and_module_array |
        target_and_module_array.each do | target_and_module_array_entry |
          patch_module = target_and_module_array_entry[ :patch_module ]
          patch_target = target_and_module_array_entry[ :patch_target ]

          next if patch_module.nil?

          # If the patch contains a target-based collection of unbound
          # methods, it was disabled previously (see the 'disable' code).
          # Re-enable by re-building the module's methods.
          #
          if target_and_module_array_entry.has_key?( :unbound_methods )

            target_and_module_array_entry[ :unbound_methods ].each do | method_name, unbound_method |
              patch_module.send( :define_method, method_name, unbound_method )
            end

            # Discard the references to the now-unneeded unbound methods.
            #
            target_and_module_array_entry.delete( :unbound_methods )

          end

          # *Always* call "prepend". If the same patch modules are being used
          # against multiple targets, the fact that the code above saw that a
          # module had been disabled for one particular target doesn't mean
          # that the module had previously been inserted into the ancestors
          # for "this" target. It might have been registered later.
          #
          # This is safe as repeat calls do nothing; they don't even reorder
          # the ancestor chain.
          #
          patch_target.prepend( patch_module )

        end
      end
    end

    # Disable a patch previously enabled with ::enable (see there for more
    # information).
    #
    # A disabled patch will still be present in a target unit's +ancestors+
    # list, but has no performance impact. Repeated enable/disable cycles
    # incur no additional runtime performance penalties.
    #
    # _Named_ parameters are:
    #
    # +extension_module+:: A module previously passed in the same-named
    #                      parameter to ::register. The instance and/or class
    #                      methods defined therein will be removed from the
    #                      previously registered target.
    #
    # Disabling the same extension multiple times has no side effects.
    #
    def self.disable( extension_module:, target_unit: nil )
      if ( target_units_hash = @@modules[ extension_module ] ).nil?
        raise "Hoodoo::Monkey::disable: Extension module '#{ extension_module.inspect }' is not registered"
      end

      target_units_hash.each_value do | target_and_module_array |
        target_and_module_array.each do | target_and_module_array_entry |
          patch_module = target_and_module_array_entry[ :patch_module ]
          patch_target = target_and_module_array_entry[ :patch_target ]

          next if patch_module.nil? || target_and_module_array_entry.has_key?( :unbound_methods )

          target_and_module_array_entry[ :unbound_methods ] = {}

          # We take unbound method references to every patch module method,
          # then remove the originals. In the re-enable code, the methods
          # are redefined in the module. This approach means that any
          # target unit with the module in its ancestors chain will see the
          # change immediately. We don't need to iterate over them.
          #
          patch_module.instance_methods( false ).each do | method_name |
            unbound_method = patch_module.instance_method( method_name )
            target_and_module_array_entry[ :unbound_methods ][ method_name ] = unbound_method
            patch_module.send( :remove_method, method_name )
          end
        end
      end
    end

    # Out-of-the-box regular monkey patches (versus chaos monkeys) for Hoodoo.
    # These typically predictably extend or modify existing Hoodoo behaviour.
    # See Hoodoo::Monkey for details.
    #
    module Patch
    end

    # Out-of-the-box chaos monkey patches (versus regular monkeys) for Hoodoo.
    # These typically provoke unpredictable states inside existing Hoodoo
    # behaviour to exercise "unhappy path" code paths. See Hoodoo::Monkey for
    # details.
    #
    module Chaos
    end
  end
end
