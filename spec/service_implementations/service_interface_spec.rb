require 'spec_helper'

class RSpecTestServiceInterfaceImplementationA < Hoodoo::ServiceImplementation
end

class RSpecTestServiceInterfaceImplementationB < Hoodoo::ServiceImplementation
end

class RSpecTestServiceInterfaceInterfaceA < Hoodoo::ServiceInterface
  interface "RSpecTestServiceInterfaceAResource" do
    version 42
    endpoint :rspec_test_service_interface_a, RSpecTestServiceInterfaceImplementationA
    actions :show, :create, :delete
    embeds :embed_one, :embed_two, :embed_three

    to_list do
      limit  25
      sort   :sort_one => [ :left, :right ], default( :sort_two ) => [ :up, :down ]
      search :search_one, :search_two, :search_three
      filter :filter_one, :filter_two, :filter_three
    end

    to_create do
      text :foo
      enum :bar, :from => [ "baz", :boo ]
    end

    to_update do
      text :hello
      uuid :world, :resource => :Earth
    end

    errors_for 'transaction' do
      error 'duplicate_transaction', status: 409, message: 'Duplicate transaction', :required => [ :client_uid ]
    end
  end
end

class RSpecTestServiceInterfaceInterfaceB < Hoodoo::ServiceInterface
  interface :RSpecTestServiceInterfaceBResource do
    endpoint :rspec_test_service_interface_b, RSpecTestServiceInterfaceImplementationB

    to_create do
      text :one
      text :two
    end

    update_same_as_create
  end
end

class RSpecTestServiceInterfaceInterfaceDefault < Hoodoo::ServiceInterface
  interface :RSpecTestServiceInterfaceDefaultResource do
    endpoint :rspec_test_service_interface_default, RSpecTestServiceInterfaceImplementationA # (sic.)
  end
end

describe Hoodoo::ServiceInterface do

  context 'DSL test classes' do

    it 'acquires defaults' do
      expect(RSpecTestServiceInterfaceInterfaceDefault.version).to eq(1)
      expect(RSpecTestServiceInterfaceInterfaceDefault.endpoint).to eq(:rspec_test_service_interface_default)
      expect(RSpecTestServiceInterfaceInterfaceDefault.resource).to be_a(Symbol)
      expect(RSpecTestServiceInterfaceInterfaceDefault.resource).to eq(:RSpecTestServiceInterfaceDefaultResource)
      expect(RSpecTestServiceInterfaceInterfaceDefault.implementation).to eq(RSpecTestServiceInterfaceImplementationA)
      expect(RSpecTestServiceInterfaceInterfaceDefault.actions).to eq(Set.new([:list, :show, :create, :update, :delete]))
      expect(RSpecTestServiceInterfaceInterfaceDefault.public_actions).to be_empty
      expect(RSpecTestServiceInterfaceInterfaceDefault.embeds).to be_empty
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_list.limit).to eq(50)
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_list.sort).to eq({"created_at" => [ "desc", "asc" ]})
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_list.default_sort_key).to eq("created_at")
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_list.default_sort_direction).to eq("desc")
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_list.search).to be_empty
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_list.filter).to be_empty
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_create).to be_nil
      expect(RSpecTestServiceInterfaceInterfaceDefault.to_update).to be_nil
    end

    # This is checking most of the DSL in non-error call cases
    #
    it 'should be correctly configured (A)' do
      expect(RSpecTestServiceInterfaceInterfaceA.version).to eq(42)
      expect(RSpecTestServiceInterfaceInterfaceA.endpoint).to eq(:rspec_test_service_interface_a)
      expect(RSpecTestServiceInterfaceInterfaceA.resource).to be_a(Symbol)
      expect(RSpecTestServiceInterfaceInterfaceA.resource).to eq(:RSpecTestServiceInterfaceAResource)
      expect(RSpecTestServiceInterfaceInterfaceA.implementation).to eq(RSpecTestServiceInterfaceImplementationA)
      expect(RSpecTestServiceInterfaceInterfaceA.actions).to eq(Set.new([:show, :create, :delete]))
      expect(RSpecTestServiceInterfaceInterfaceA.embeds).to eq(["embed_one", "embed_two", "embed_three"])
      expect(RSpecTestServiceInterfaceInterfaceA.to_list.limit).to eq(25)
      expect(RSpecTestServiceInterfaceInterfaceA.to_list.sort).to eq({"created_at" => [ "desc", "asc" ], "sort_one" => [ "left", "right" ], "sort_two" => [ "up", "down" ]})
      expect(RSpecTestServiceInterfaceInterfaceA.to_list.default_sort_key).to eq("sort_two")
      expect(RSpecTestServiceInterfaceInterfaceA.to_list.default_sort_direction).to eq("up")
      expect(RSpecTestServiceInterfaceInterfaceA.to_list.search).to eq(["search_one", "search_two", "search_three"])
      expect(RSpecTestServiceInterfaceInterfaceA.to_list.filter).to eq(["filter_one", "filter_two", "filter_three"])
      expect(RSpecTestServiceInterfaceInterfaceA.to_create).to_not be_nil
      expect(RSpecTestServiceInterfaceInterfaceA.to_create.get_schema().properties['foo']).to be_a(Hoodoo::Presenters::Text)
      expect(RSpecTestServiceInterfaceInterfaceA.to_create.get_schema().properties['bar']).to be_a(Hoodoo::Presenters::Enum)
      expect(RSpecTestServiceInterfaceInterfaceA.to_create.get_schema().properties['bar'].from).to eq(["baz", "boo"])
      expect(RSpecTestServiceInterfaceInterfaceA.to_update.get_schema().properties['hello']).to be_a(Hoodoo::Presenters::Text)
      expect(RSpecTestServiceInterfaceInterfaceA.to_update.get_schema().properties['world']).to be_a(Hoodoo::Presenters::UUID)
      expect(RSpecTestServiceInterfaceInterfaceA.to_update.get_schema().properties['world'].resource).to eq(:Earth)
      expect(RSpecTestServiceInterfaceInterfaceA.errors_for.describe('transaction.duplicate_transaction')).to eq({'status' => 409, 'message' => 'Duplicate transaction', 'required' => [ :client_uid ]})
    end

    # This is just testing #update_same_as_create
    #
    it 'should be correctly configured (B)' do
      expect(RSpecTestServiceInterfaceInterfaceB.to_update).to_not be_nil
      expect(RSpecTestServiceInterfaceInterfaceB.to_update.get_schema().properties['one']).to be_a(Hoodoo::Presenters::Text)
      expect(RSpecTestServiceInterfaceInterfaceB.to_update.get_schema().properties['two']).to be_a(Hoodoo::Presenters::Text)
    end
  end

  context 'DSL errors' do
    it 'should complain about interface redefinition' do
      expect {
        RSpecTestServiceInterfaceInterfaceB.interface :FooB do
        end
      }.to raise_error(RuntimeError, "Hoodoo::ServiceInterface subclass unexpectedly ran ::interface more than once")
    end

    it 'should complain about no endpoint' do
      class RSpecTestServiceInterfaceInterfaceC < Hoodoo::ServiceInterface
      end

      expect {
        RSpecTestServiceInterfaceInterfaceC.interface :FooC do
        end
      }.to raise_error(RuntimeError, "Hoodoo::ServiceInterface subclasses must always call the 'endpoint' DSL method in their interface descriptions")
    end

    it 'should complain about incorrect implementation classes' do
      class RSpecTestServiceInterfaceInterfaceD < Hoodoo::ServiceInterface
      end

      expect {
        RSpecTestServiceInterfaceInterfaceD.interface :FooD do
          endpoint :an_endpoint, Hoodoo::ServiceImplementation # Not a *subclass*, so just as invalid as some other unrelated Class
        end
      }.to raise_error(RuntimeError, "Hoodoo::ServiceInterface#endpoint must provide Hoodoo::ServiceImplementation subclasses, but 'Hoodoo::ServiceImplementation' was given instead")
    end

    context 'in #action' do
      it 'should complain about incorrect actions' do
        class RSpecTestServiceInterfaceImplementationE < Hoodoo::ServiceImplementation
        end
        class RSpecTestServiceInterfaceInterfaceE < Hoodoo::ServiceInterface
        end

        expect {
          RSpecTestServiceInterfaceInterfaceE.interface :FooE do
            endpoint :an_endpoint, RSpecTestServiceInterfaceImplementationE
            actions :create, :made_this_up, :delete, :made_this_up_too
          end
        }.to raise_error(RuntimeError, "Hoodoo::ServiceInterface#actions does not recognise one or more actions: 'made_this_up, made_this_up_too'")
      end
    end

    context 'in #public_action' do
      it 'should complain about incorrect actions' do
        class RSpecTestServiceInterfaceImplementationF < Hoodoo::ServiceImplementation
        end
        class RSpecTestServiceInterfaceInterfaceF < Hoodoo::ServiceInterface
        end

        expect {
          RSpecTestServiceInterfaceInterfaceF.interface :FooF do
            endpoint :an_endpoint, RSpecTestServiceInterfaceImplementationF
            public_actions :create, :made_this_up, :delete, :made_this_up_too
          end
        }.to raise_error(RuntimeError, "Hoodoo::ServiceInterface#public_actions does not recognise one or more actions: 'made_this_up, made_this_up_too'")
      end
    end

    # This is really an internal sanity test for code coverage purposes...
    #
    it 'should complain about incorrect instantiation' do
      expect {
        Hoodoo::ServiceInterface::ToListDSL.new( Array.new ) do
        end
      }.to raise_error(RuntimeError, "Hoodoo::ServiceInstance::ToListDSL\#initialize requires an Hoodoo::ServiceInstance::ToList instance - got 'Array'")
    end

    context 'in #limit' do
      it 'should complain about incorrect types' do
        expect {
          Hoodoo::ServiceInterface::ToListDSL.new( Hoodoo::ServiceInterface::ToList.new ) do
            limit "hello"
          end
        }.to raise_error(RuntimeError, "Hoodoo::ServiceInstance::ToListDSL\#limit requires an Integer - got 'String'")
      end
    end

    context 'in #sort' do
      it 'should complain about incorrect types' do
        expect {
          Hoodoo::ServiceInterface::ToListDSL.new( Hoodoo::ServiceInterface::ToList.new ) do
            sort "hello"
          end
        }.to raise_error(RuntimeError, "Hoodoo::ServiceInstance::ToListDSL\#sort requires a Hash - got 'String'")
      end
    end

    context 'in #default' do
      it 'should complain about incorrect types' do
        expect {
          Hoodoo::ServiceInterface::ToListDSL.new( Hoodoo::ServiceInterface::ToList.new ) do
            default 42
          end
        }.to raise_error(RuntimeError, "Hoodoo::ServiceInstance::ToListDSL\#default requires a String or Symbol - got 'Fixnum'")
      end
    end
  end
end
