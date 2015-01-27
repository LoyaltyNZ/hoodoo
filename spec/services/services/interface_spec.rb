require 'spec_helper'

class RSpecTestInterfaceImplementationA < Hoodoo::Services::Implementation
end

class RSpecTestInterfaceImplementationB < Hoodoo::Services::Implementation
end

class RSpecTestInterfaceInterfaceA < Hoodoo::Services::Interface
  interface "RSpecTestInterfaceAResource" do
    version 42
    endpoint :rspec_test_interface_a, RSpecTestInterfaceImplementationA
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

class RSpecTestInterfaceInterfaceB < Hoodoo::Services::Interface
  interface :RSpecTestInterfaceBResource do
    endpoint :rspec_test_interface_b, RSpecTestInterfaceImplementationB

    to_create do
      text :one
      text :two
    end

    update_same_as_create
  end
end

class RSpecTestInterfaceInterfaceDefault < Hoodoo::Services::Interface
  interface :RSpecTestInterfaceDefaultResource do
    endpoint :rspec_test_interface_default, RSpecTestInterfaceImplementationA # (sic.)
  end
end

describe Hoodoo::Services::Interface do

  context 'DSL test classes' do

    it 'acquires defaults' do
      expect(RSpecTestInterfaceInterfaceDefault.version).to eq(1)
      expect(RSpecTestInterfaceInterfaceDefault.endpoint).to eq(:rspec_test_interface_default)
      expect(RSpecTestInterfaceInterfaceDefault.resource).to be_a(Symbol)
      expect(RSpecTestInterfaceInterfaceDefault.resource).to eq(:RSpecTestInterfaceDefaultResource)
      expect(RSpecTestInterfaceInterfaceDefault.implementation).to eq(RSpecTestInterfaceImplementationA)
      expect(RSpecTestInterfaceInterfaceDefault.actions).to eq(Set.new([:list, :show, :create, :update, :delete]))
      expect(RSpecTestInterfaceInterfaceDefault.public_actions).to be_empty
      expect(RSpecTestInterfaceInterfaceDefault.embeds).to be_empty
      expect(RSpecTestInterfaceInterfaceDefault.to_list.limit).to eq(50)
      expect(RSpecTestInterfaceInterfaceDefault.to_list.sort).to eq({"created_at" => [ "desc", "asc" ]})
      expect(RSpecTestInterfaceInterfaceDefault.to_list.default_sort_key).to eq("created_at")
      expect(RSpecTestInterfaceInterfaceDefault.to_list.default_sort_direction).to eq("desc")
      expect(RSpecTestInterfaceInterfaceDefault.to_list.search).to be_empty
      expect(RSpecTestInterfaceInterfaceDefault.to_list.filter).to be_empty
      expect(RSpecTestInterfaceInterfaceDefault.to_create).to be_nil
      expect(RSpecTestInterfaceInterfaceDefault.to_update).to be_nil
    end

    # This is checking most of the DSL in non-error call cases
    #
    it 'should be correctly configured (A)' do
      expect(RSpecTestInterfaceInterfaceA.version).to eq(42)
      expect(RSpecTestInterfaceInterfaceA.endpoint).to eq(:rspec_test_interface_a)
      expect(RSpecTestInterfaceInterfaceA.resource).to be_a(Symbol)
      expect(RSpecTestInterfaceInterfaceA.resource).to eq(:RSpecTestInterfaceAResource)
      expect(RSpecTestInterfaceInterfaceA.implementation).to eq(RSpecTestInterfaceImplementationA)
      expect(RSpecTestInterfaceInterfaceA.actions).to eq(Set.new([:show, :create, :delete]))
      expect(RSpecTestInterfaceInterfaceA.embeds).to eq(["embed_one", "embed_two", "embed_three"])
      expect(RSpecTestInterfaceInterfaceA.to_list.limit).to eq(25)
      expect(RSpecTestInterfaceInterfaceA.to_list.sort).to eq({"created_at" => [ "desc", "asc" ], "sort_one" => [ "left", "right" ], "sort_two" => [ "up", "down" ]})
      expect(RSpecTestInterfaceInterfaceA.to_list.default_sort_key).to eq("sort_two")
      expect(RSpecTestInterfaceInterfaceA.to_list.default_sort_direction).to eq("up")
      expect(RSpecTestInterfaceInterfaceA.to_list.search).to eq(["search_one", "search_two", "search_three"])
      expect(RSpecTestInterfaceInterfaceA.to_list.filter).to eq(["filter_one", "filter_two", "filter_three"])
      expect(RSpecTestInterfaceInterfaceA.to_create).to_not be_nil
      expect(RSpecTestInterfaceInterfaceA.to_create.get_schema().properties['foo']).to be_a(Hoodoo::Presenters::Text)
      expect(RSpecTestInterfaceInterfaceA.to_create.get_schema().properties['bar']).to be_a(Hoodoo::Presenters::Enum)
      expect(RSpecTestInterfaceInterfaceA.to_create.get_schema().properties['bar'].from).to eq(["baz", "boo"])
      expect(RSpecTestInterfaceInterfaceA.to_update.get_schema().properties['hello']).to be_a(Hoodoo::Presenters::Text)
      expect(RSpecTestInterfaceInterfaceA.to_update.get_schema().properties['world']).to be_a(Hoodoo::Presenters::UUID)
      expect(RSpecTestInterfaceInterfaceA.to_update.get_schema().properties['world'].resource).to eq(:Earth)
      expect(RSpecTestInterfaceInterfaceA.errors_for.describe('transaction.duplicate_transaction')).to eq({'status' => 409, 'message' => 'Duplicate transaction', 'required' => [ :client_uid ]})
    end

    # This is just testing #update_same_as_create
    #
    it 'should be correctly configured (B)' do
      expect(RSpecTestInterfaceInterfaceB.to_update).to_not be_nil
      expect(RSpecTestInterfaceInterfaceB.to_update.get_schema().properties['one']).to be_a(Hoodoo::Presenters::Text)
      expect(RSpecTestInterfaceInterfaceB.to_update.get_schema().properties['two']).to be_a(Hoodoo::Presenters::Text)
    end
  end

  context 'DSL errors' do
    it 'should complain about interface redefinition' do
      expect {
        RSpecTestInterfaceInterfaceB.interface :FooB do
        end
      }.to raise_error(RuntimeError, "Hoodoo::Services::Interface subclass unexpectedly ran ::interface more than once")
    end

    it 'should complain about no endpoint' do
      class RSpecTestInterfaceInterfaceC < Hoodoo::Services::Interface
      end

      expect {
        RSpecTestInterfaceInterfaceC.interface :FooC do
        end
      }.to raise_error(RuntimeError, "Hoodoo::Services::Interface subclasses must always call the 'endpoint' DSL method in their interface descriptions")
    end

    it 'should complain about incorrect implementation classes' do
      class RSpecTestInterfaceInterfaceD < Hoodoo::Services::Interface
      end

      expect {
        RSpecTestInterfaceInterfaceD.interface :FooD do
          endpoint :an_endpoint, Hoodoo::Services::Implementation # Not a *subclass*, so just as invalid as some other unrelated Class
        end
      }.to raise_error(RuntimeError, "Hoodoo::Services::Interface#endpoint must provide Hoodoo::Services::Implementation subclasses, but 'Hoodoo::Services::Implementation' was given instead")
    end

    context 'in #action' do
      it 'should complain about incorrect actions' do
        class RSpecTestInterfaceImplementationE < Hoodoo::Services::Implementation
        end
        class RSpecTestInterfaceInterfaceE < Hoodoo::Services::Interface
        end

        expect {
          RSpecTestInterfaceInterfaceE.interface :FooE do
            endpoint :an_endpoint, RSpecTestInterfaceImplementationE
            actions :create, :made_this_up, :delete, :made_this_up_too
          end
        }.to raise_error(RuntimeError, "Hoodoo::Services::Interface#actions does not recognise one or more actions: 'made_this_up, made_this_up_too'")
      end
    end

    context 'in #public_action' do
      it 'should complain about incorrect actions' do
        class RSpecTestInterfaceImplementationF < Hoodoo::Services::Implementation
        end
        class RSpecTestInterfaceInterfaceF < Hoodoo::Services::Interface
        end

        expect {
          RSpecTestInterfaceInterfaceF.interface :FooF do
            endpoint :an_endpoint, RSpecTestInterfaceImplementationF
            public_actions :create, :made_this_up, :delete, :made_this_up_too
          end
        }.to raise_error(RuntimeError, "Hoodoo::Services::Interface#public_actions does not recognise one or more actions: 'made_this_up, made_this_up_too'")
      end
    end

    # This is really an internal sanity test for code coverage purposes...
    #
    it 'should complain about incorrect instantiation' do
      expect {
        Hoodoo::Services::Interface::ToListDSL.new( Array.new ) do
        end
      }.to raise_error(RuntimeError, "Hoodoo::Services::ServiceInstance::ToListDSL\#initialize requires an Hoodoo::Services::ServiceInstance::ToList instance - got 'Array'")
    end

    context 'in #limit' do
      it 'should complain about incorrect types' do
        expect {
          Hoodoo::Services::Interface::ToListDSL.new( Hoodoo::Services::Interface::ToList.new ) do
            limit "hello"
          end
        }.to raise_error(RuntimeError, "Hoodoo::Services::ServiceInstance::ToListDSL\#limit requires an Integer - got 'String'")
      end
    end

    context 'in #sort' do
      it 'should complain about incorrect types' do
        expect {
          Hoodoo::Services::Interface::ToListDSL.new( Hoodoo::Services::Interface::ToList.new ) do
            sort "hello"
          end
        }.to raise_error(RuntimeError, "Hoodoo::Services::ServiceInstance::ToListDSL\#sort requires a Hash - got 'String'")
      end
    end

    context 'in #default' do
      it 'should complain about incorrect types' do
        expect {
          Hoodoo::Services::Interface::ToListDSL.new( Hoodoo::Services::Interface::ToList.new ) do
            default 42
          end
        }.to raise_error(RuntimeError, "Hoodoo::Services::ServiceInstance::ToListDSL\#default requires a String or Symbol - got 'Fixnum'")
      end
    end
  end
end
