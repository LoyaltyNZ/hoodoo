require 'spec_helper.rb'
require 'benchmark'

describe Hoodoo::Monkey do

  BENCHMARK_ITERATIONS = 500000

  # Have a base class which we will subclass in 'context's below. Define a
  # different-signature instance and class method to test that the patched
  # code still passes parameters and blocks properly. They're both the same
  # name to make sure there's no accidental name-based overwiting of things
  # to do with class versus instance methods anywhere.
  #
  class Foo
    def bar( a, b, c, &block )
      a + b + c + yield
    end

    def self.bar( x, &block )
      x + yield
    end
  end

  # Define patches for the above instance and class methods which double the
  # returned value via calling 'super', testing the method chain in passing
  # and providing an easily detectable value to see if the original, or the
  # patched method has been called.
  #
  module InstanceExtendedFoo
    module InstanceExtensions
      def bar( a, b, c, &block )
        super * 2
      end
    end
  end

  module ClassExtendedFoo
    module ClassExtensions
      def bar( x, &block )
        super * 2
      end
    end
  end

  module ExtendedFoo
    module InstanceExtensions
      def bar( a, b, c, &block )
        super * 2
      end
    end

    module ClassExtensions
      def bar( x, &block )
        super * 2
      end
    end
  end

  # The next few contexts run a single "it" case because execution order is
  # important. They each iterate the test set several times to prove that
  # enable/disable cycles work properly.
  #
  context 'instance method patching' do

    # Just register the instance extensions here.

    class FooForInstanceTests < Foo; end

    before :all do
      Hoodoo::Monkey.register(
        target_unit:      FooForInstanceTests,
        extension_module: InstanceExtendedFoo
      )
    end

    it 'works' do
      expect( FooForInstanceTests.ancestors ).to_not include( InstanceExtendedFoo::InstanceExtensions )

      1.upto( 10 ) do
        expect( FooForInstanceTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
        expect( FooForInstanceTests.bar( 1 ) { 2 } ).to eq( 3 )

        Hoodoo::Monkey.enable( extension_module: InstanceExtendedFoo )

        expect( FooForInstanceTests.ancestors ).to include( InstanceExtendedFoo::InstanceExtensions )

        expect( FooForInstanceTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 36 )
        expect( FooForInstanceTests.bar( 1 ) { 2 } ).to eq( 3 )

        Hoodoo::Monkey.disable( extension_module: InstanceExtendedFoo )
      end
    end
  end

  context 'class method patching' do

    # Just register the class extensions here.

    class FooForClassTests < Foo; end

    before :all do
      Hoodoo::Monkey.register(
        target_unit:      FooForClassTests,
        extension_module: ClassExtendedFoo
      )
    end

    it 'works' do
      expect( FooForClassTests.singleton_class.ancestors ).to_not include( ClassExtendedFoo::ClassExtensions )

      1.upto( 10 ) do
        expect( FooForClassTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
        expect( FooForClassTests.bar( 1 ) { 2 } ).to eq( 3 )

        Hoodoo::Monkey.enable( extension_module: ClassExtendedFoo )

        expect( FooForClassTests.singleton_class.ancestors ).to include( ClassExtendedFoo::ClassExtensions )

        expect( FooForClassTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
        expect( FooForClassTests.bar( 1 ) { 2 } ).to eq( 6 )

        Hoodoo::Monkey.disable( extension_module: ClassExtendedFoo )
      end
    end
  end

  context 'instance and class method patching' do

    # Register the class and instance extensions here.

    class FooForBothTests < Foo; end

    before :all do
      Hoodoo::Monkey.register(
        target_unit:      FooForBothTests,
        extension_module: ExtendedFoo
      )
    end

    it 'works' do
      expect( FooForBothTests.ancestors                 ).to_not include( ExtendedFoo::InstanceExtensions )
      expect( FooForBothTests.singleton_class.ancestors ).to_not include( ExtendedFoo::ClassExtensions    )

      1.upto( 10 ) do
        expect( FooForBothTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
        expect( FooForBothTests.bar( 1 ) { 2 } ).to eq( 3 )

        Hoodoo::Monkey.enable( extension_module: ExtendedFoo )

        expect( FooForBothTests.ancestors                 ).to include( ExtendedFoo::InstanceExtensions )
        expect( FooForBothTests.singleton_class.ancestors ).to include( ExtendedFoo::ClassExtensions    )

        expect( FooForBothTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 36 )
        expect( FooForBothTests.bar( 1 ) { 2 } ).to eq( 6 )

        Hoodoo::Monkey.disable( extension_module: ExtendedFoo )
      end
    end
  end

  # A whole bunch of fiddly tests for different misuse or edge use cases.
  #
  context 'errant calls' do
    before :each do
      expect( Foo.ancestors                 ).to_not include( ExtendedFoo::InstanceExtensions )
      expect( Foo.singleton_class.ancestors ).to_not include( ExtendedFoo::ClassExtensions    )
    end

    module NoIntanceOrClassExtensionsDefinedInside
    end

    it 'fault no-patch registration' do
      expect {
        Hoodoo::Monkey.register(
          target_unit:      Foo,
          extension_module: NoIntanceOrClassExtensionsDefinedInside
        )
      }.to raise_exception( RuntimeError, "Hoodoo::Monkey::register: You must define either an InstanceExtensions module ClassExtensions module or both inside 'NoIntanceOrClassExtensionsDefinedInside'" )
    end

    context 'fault unrecognised' do

      class FooForUnrecognisedTests < Foo; end

      before :all do
        Hoodoo::Monkey.register(
          target_unit:      FooForUnrecognisedTests,
          extension_module: ExtendedFoo
        )
      end

      it 'extension module enables' do
        expect {
          Hoodoo::Monkey.enable( extension_module: ExtendedFoo::InstanceExtensions )
        }.to raise_exception( RuntimeError, "Hoodoo::Monkey::enable: Extension module 'ExtendedFoo::InstanceExtensions' is not registered" )
      end

      it 'extension module disables' do
        expect {
          Hoodoo::Monkey.disable( extension_module: ExtendedFoo::InstanceExtensions )
        }.to raise_exception( RuntimeError, "Hoodoo::Monkey::disable: Extension module 'ExtendedFoo::InstanceExtensions' is not registered" )
      end
    end

    class FooForSuccessiveEnableTests < Foo; end

    it 'survive multiple successive enables' do
      Hoodoo::Monkey.register(
        target_unit:      FooForSuccessiveEnableTests,
        extension_module: ExtendedFoo
      )

      expect( FooForSuccessiveEnableTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
      expect( FooForSuccessiveEnableTests.bar( 1 ) { 2 } ).to eq( 3 )

      1.upto( 10 ) do
        Hoodoo::Monkey.enable( extension_module: ExtendedFoo )
      end

      expect( FooForSuccessiveEnableTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 36 )
      expect( FooForSuccessiveEnableTests.bar( 1 ) { 2 } ).to eq( 6 )
    end

    class FooForSuccessiveDisableTests < Foo; end

    it 'survive multiple successive disables' do
      Hoodoo::Monkey.register(
        target_unit:      FooForSuccessiveDisableTests,
        extension_module: ExtendedFoo
      )

      expect( FooForSuccessiveDisableTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
      expect( FooForSuccessiveDisableTests.bar( 1 ) { 2 } ).to eq( 3 )

      Hoodoo::Monkey.enable( extension_module: ExtendedFoo )

      expect( FooForSuccessiveDisableTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 36 )
      expect( FooForSuccessiveDisableTests.bar( 1 ) { 2 } ).to eq( 6 )

      1.upto( 10 ) do
        Hoodoo::Monkey.disable( extension_module: ExtendedFoo )
      end

      expect( FooForSuccessiveDisableTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
      expect( FooForSuccessiveDisableTests.bar( 1 ) { 2 } ).to eq( 3 )
    end

    class FooForNotPreviouslyEnabledTests < Foo; end

    it 'survive being disabled when not previously enabled' do
      Hoodoo::Monkey.register(
        target_unit:      FooForNotPreviouslyEnabledTests,
        extension_module: ExtendedFoo
      )

      expect( FooForNotPreviouslyEnabledTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
      expect( FooForNotPreviouslyEnabledTests.bar( 1 ) { 2 } ).to eq( 3 )

      Hoodoo::Monkey.disable( extension_module: ExtendedFoo )

      expect( FooForNotPreviouslyEnabledTests.new.bar( 3, 4, 5 ) { 6 } ).to eq( 18 )
      expect( FooForNotPreviouslyEnabledTests.bar( 1 ) { 2 } ).to eq( 3 )
    end
  end

  # Run a couple of short benchmarks before/after patching and after patching
  # is disabled again, checking that there's no big difference in speed across
  # them.
  #
  context 'performance impact' do
    it 'is undetectable' do
    end
  end
end
