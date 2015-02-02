require 'spec_helper'

describe Hoodoo::Services::Session do

  before do
    Hoodoo::Services::Session.testing(false)
  end

  after do
    Hoodoo::Services::Session.testing(true)
  end

  let :request do
    double(env: {})
  end

  describe '#self.load_session' do

    it 'should raise an error if memcache_url is nil' do
      expect {
        Hoodoo::Services::Session.load_session(nil, '0123456789ABCDEF', request)
      }.to raise_error "Hoodoo::Services::Middleware memcache server URL is nil or empty"
    end

    it 'should raise an error if memcache_url is empty' do
      expect {
        Hoodoo::Services::Session.load_session('', '0123456789ABCDEF', request)
      }.to raise_error "Hoodoo::Services::Middleware memcache server URL is nil or empty"
    end

    it 'should return nil if session_id is nil' do
      session = Hoodoo::Services::Session.load_session('url', nil, request)
      expect(session).to be_nil
    end

    it 'should return nil if session_id is empty' do
      session = Hoodoo::Services::Session.load_session('url', '', request)
      expect(session).to be_nil
    end

    it 'should return nil if session_id is less than 32 chars' do
      session = Hoodoo::Services::Session.load_session('url', '0123456789ABCDE', request)
      expect(session).to be_nil
    end

    it 'should call connect_memcache and raise error if return is nil' do
      expect(Hoodoo::Services::Session).to receive(:connect_memcache).with('url').and_return(nil)
      expect {
        Hoodoo::Services::Session.load_session('url', '0123456789ABCDEF0123456789ABCDEF', request)
      }.to raise_error "Hoodoo::Services::Middleware cannot connect to memcache server 'url'"
    end

    it 'should call get on memcache with correct key and return nil if not found' do
      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:get).with("session_0123456789ABCDEF0123456789ABCDEF").and_return(nil)
      expect(Hoodoo::Services::Session).to receive(:connect_memcache).and_return(mock_memcache)

      session = Hoodoo::Services::Session.load_session('url', '0123456789ABCDEF0123456789ABCDEF', request)
      expect(session).to be_nil
    end

    it 'should warn and return nil if memcache get throws' do
      session = 'asjcbasybcoiqhcg3q'

      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:get).with("session_0123456789ABCDEF0123456789ABCDEF").and_raise(Exception.new)
      expect(Hoodoo::Services::Session).to receive(:connect_memcache).and_return(mock_memcache)

      expect(Hoodoo::Services::Middleware.logger).to receive(:warn)

      session = Hoodoo::Services::Session.load_session('url', '0123456789ABCDEF0123456789ABCDEF', request)
      expect(session).to be_nil
    end

    it 'should return new session with correct params if all is well' do

      session_hash = {
        "participant_id" => "TESTPART1",
        "outlet_id" => "TESTOUTLET1",
        "roles" => "TESTROLE1,TESTROLE2",
      }

      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:get).with("session_0123456789ABCDEF0123456789ABCDEF").and_return(session_hash)
      expect(Hoodoo::Services::Session).to receive(:connect_memcache).and_return(mock_memcache)

      session = Hoodoo::Services::Session.load_session('url', '0123456789ABCDEF0123456789ABCDEF', request)
      expect(session.id).to eq('0123456789ABCDEF0123456789ABCDEF')
      expect(session.participant_id).to eq(session_hash["participant_id"])
      expect(session.outlet_id).to eq(session_hash["outlet_id"])
      expect(session.roles).to eq(["TESTROLE1","TESTROLE2"])
    end
  end

  describe '#connect_memcache' do
    it 'should call Dalli and return a new client' do
      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:stats).and_return true
      expect(Dalli::Client).to receive(:new).with('one',{ :compress=>false, :serializer => JSON }).and_return(mock_memcache)
      expect(Hoodoo::Services::Session.send(:connect_memcache, 'one')).to eq(mock_memcache)
    end

    it 'should return nil if Dalli::Client.new raises an error' do
      expect(Dalli::Client).to receive(:new) do
        raise "Error!"
      end
      expect(Hoodoo::Services::Session.send(:connect_memcache, 'one')).to be_nil
    end

    it 'should return nil if Dalli::Client stats call raises error' do
      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:stats) do
        raise "Error!"
      end
      expect(Dalli::Client).to receive(:new).with('one',{ :compress=>false, :serializer => JSON }).and_return(mock_memcache)
      expect(Hoodoo::Services::Session.send(:connect_memcache, 'one')).to be_nil
    end
  end

  describe '#initialize' do
    it 'should load correct options' do
      s = Hoodoo::Services::Session.new({
        :participant_id => "TESTPART1",
        :outlet_id => "TESTOUTLET1",
        :roles => "TESTROLE1,TESTROLE2",
      })

      expect(s.participant_id).to eq("TESTPART1")
      expect(s.outlet_id).to eq("TESTOUTLET1")
      expect(s.roles).to eq(["TESTROLE1","TESTROLE2"])
    end
    it 'should set options to defaults when options empty' do
      s = Hoodoo::Services::Session.new

      expect(s.participant_id).to eq(nil)
      expect(s.outlet_id).to eq(nil)
      expect(s.roles).to eq([])
    end
  end

  describe '#has_role?' do
    it 'should return true if role exists in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_role?('two')).to be_truthy
    end

    it 'should return false if role does not exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_role?('four')).to be_falsy
    end

    it 'should return false if session has no roles' do
      s = Hoodoo::Services::Session.new({
        :roles => ''
      })

      expect(s.has_role?('one')).to be_falsy
    end
  end

  describe '#has_all_roles?' do
    it 'should return true if one role exists in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_all_roles?(['one'])).to be_truthy
    end

    it 'should return true if some roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_all_roles?(['two','three'])).to be_truthy
    end

    it 'should return true if all roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_all_roles?(['one','two','three'])).to be_truthy
    end

    it 'should return false if no roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'four,five,six'
      })

      expect(s.has_all_roles?(['one','two','three'])).to be_falsy
    end

    it 'should return false if only some roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'four,five,six'
      })

      expect(s.has_all_roles?(['one','five'])).to be_falsy
    end
  end

  describe '#has_any_roles?' do
    it 'should return true if one role exists in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_any_roles?(['one'])).to be_truthy
    end

    it 'should return true if some roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_any_roles?(['two','three'])).to be_truthy
    end

    it 'should return true if all roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'one,two,three'
      })

      expect(s.has_any_roles?(['one','two','three'])).to be_truthy
    end

    it 'should return true if only some roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'four,five,six'
      })

      expect(s.has_any_roles?(['one','five'])).to be_truthy
    end

    it 'should return false if no roles exist in session' do
      s = Hoodoo::Services::Session.new({
        :roles => 'four,five,six'
      })

      expect(s.has_any_roles?(['one','two','three'])).to be_falsy
    end
  end

  describe 'outlet_id_override' do

    let :session do
      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:get).with("session_0123456789ABCDEF0123456789ABCDEF").and_return(session_hash)
      expect(Hoodoo::Services::Session).to receive(:connect_memcache).and_return(mock_memcache)
      Hoodoo::Services::Session.load_session('url', '0123456789ABCDEF0123456789ABCDEF', request)
    end

    context 'with allow_outlet_id_override role' do
      let :session_hash do
        {
          "outlet_id" => "TESTOUTLET1",
          "roles" => "TESTROLE1,TESTROLE2,allow_outlet_id_override",
        }
      end

      let :request do
        double(:env => {'HTTP_X_OUTLET_ID' => 'TESTOUTLET2'})
      end

      it 'should set the outlet id to passed if they have the role allow_outlet_id_override' do
        expect(session.outlet_id).to eq 'TESTOUTLET2'
      end
    end

    context 'without allow_outlet_id_override role' do
      let :session_hash do
        {
          "outlet_id" => "TESTOUTLET1",
          "roles" => "TESTROLE1,TESTROLE2",
        }
      end

      let :request do
        double(:env => {'HTTP_X_OUTLET_ID' => 'HACKED_OUTLET_ID'})
      end

      it 'should NOT set the outlet id to passed if they DONT have the role allow_outlet_id_override' do
        expect(session.outlet_id).to eq 'TESTOUTLET1'
      end

    end
  end
end
