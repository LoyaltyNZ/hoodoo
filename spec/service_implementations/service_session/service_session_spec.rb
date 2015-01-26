require 'spec_helper'

describe Hoodoo::ServiceSession do

  before do
    Hoodoo::ServiceSession.testing(false)
  end

  after do
    Hoodoo::ServiceSession.testing(true)
  end

  describe '#self.load_session' do

    it 'should raise an error if memcache_url is nil' do
      expect {
        Hoodoo::ServiceSession.load_session(nil, '0123456789ABCDEF')
      }.to raise_error "Hoodoo::ServiceMiddleware memcache server URL is nil or empty"
    end

    it 'should raise an error if memcache_url is empty' do
      expect {
        Hoodoo::ServiceSession.load_session('', '0123456789ABCDEF')
      }.to raise_error "Hoodoo::ServiceMiddleware memcache server URL is nil or empty"
    end

    it 'should return nil if session_id is nil' do
      session = Hoodoo::ServiceSession.load_session('url', nil)
      expect(session).to be_nil
    end

    it 'should return nil if session_id is empty' do
      session = Hoodoo::ServiceSession.load_session('url', '')
      expect(session).to be_nil
    end

    it 'should return nil if session_id is less than 32 chars' do
      session = Hoodoo::ServiceSession.load_session('url', '0123456789ABCDE')
      expect(session).to be_nil
    end

    it 'should call connect_memcache and raise error if return is nil' do
      expect(Hoodoo::ServiceSession).to receive(:connect_memcache).with('url').and_return(nil)
      expect {
        Hoodoo::ServiceSession.load_session('url', '0123456789ABCDEF0123456789ABCDEF')
      }.to raise_error "Hoodoo::ServiceMiddleware cannot connect to memcache server 'url'"
    end

    it 'should call get on memcache with correct key and return nil if not found' do
      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:get).with("session_0123456789ABCDEF0123456789ABCDEF").and_return(nil)
      expect(Hoodoo::ServiceSession).to receive(:connect_memcache).and_return(mock_memcache)

      session = Hoodoo::ServiceSession.load_session('url', '0123456789ABCDEF0123456789ABCDEF')
      expect(session).to be_nil
    end

    it 'should warn and return nil if memcache get throws' do
      session = 'asjcbasybcoiqhcg3q'

      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:get).with("session_0123456789ABCDEF0123456789ABCDEF").and_raise(Exception.new)
      expect(Hoodoo::ServiceSession).to receive(:connect_memcache).and_return(mock_memcache)

      expect(Hoodoo::ServiceMiddleware.logger).to receive(:warn)

      session = Hoodoo::ServiceSession.load_session('url', '0123456789ABCDEF0123456789ABCDEF')
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
      expect(Hoodoo::ServiceSession).to receive(:connect_memcache).and_return(mock_memcache)

      session = Hoodoo::ServiceSession.load_session('url', '0123456789ABCDEF0123456789ABCDEF')
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
      expect(Hoodoo::ServiceSession.send(:connect_memcache, 'one')).to eq(mock_memcache)
    end

    it 'should return nil if Dalli::Client.new raises an error' do
      expect(Dalli::Client).to receive(:new) do
        raise "Error!"
      end
      expect(Hoodoo::ServiceSession.send(:connect_memcache, 'one')).to be_nil
    end

    it 'should return nil if Dalli::Client stats call raises error' do
      mock_memcache = double('memcache')
      expect(mock_memcache).to receive(:stats) do
        raise "Error!"
      end
      expect(Dalli::Client).to receive(:new).with('one',{ :compress=>false, :serializer => JSON }).and_return(mock_memcache)
      expect(Hoodoo::ServiceSession.send(:connect_memcache, 'one')).to be_nil
    end
  end

  describe '#initialize' do
    it 'should load correct options' do
      s = Hoodoo::ServiceSession.new({
        :participant_id => "TESTPART1",
        :outlet_id => "TESTOUTLET1",
        :roles => "TESTROLE1,TESTROLE2",
      })

      expect(s.participant_id).to eq("TESTPART1")
      expect(s.outlet_id).to eq("TESTOUTLET1")
      expect(s.roles).to eq(["TESTROLE1","TESTROLE2"])
    end
    it 'should set options to defaults when options empty' do
      s = Hoodoo::ServiceSession.new

      expect(s.participant_id).to eq(nil)
      expect(s.outlet_id).to eq(nil)
      expect(s.roles).to eq([])
    end
  end

  describe '#has_role?' do
    it 'should return true if role exists in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_role?('two')).to be_truthy
    end

    it 'should return false if role does not exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_role?('four')).to be_falsy
    end

    it 'should return false if session has no roles' do
      s = Hoodoo::ServiceSession.new({
        :roles => ''
      })

      expect(s.has_role?('one')).to be_falsy
    end
  end

  describe '#has_all_roles?' do
    it 'should return true if one role exists in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_all_roles?(['one'])).to be_truthy
    end

    it 'should return true if some roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_all_roles?(['two','three'])).to be_truthy
    end

    it 'should return true if all roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_all_roles?(['one','two','three'])).to be_truthy
    end

    it 'should return false if no roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'four,five,six'
      })

      expect(s.has_all_roles?(['one','two','three'])).to be_falsy
    end

    it 'should return false if only some roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'four,five,six'
      })

      expect(s.has_all_roles?(['one','five'])).to be_falsy
    end
  end

  describe '#has_any_roles?' do
    it 'should return true if one role exists in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_any_roles?(['one'])).to be_truthy
    end

    it 'should return true if some roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_any_roles?(['two','three'])).to be_truthy
    end

    it 'should return true if all roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'one,two,three'
      })

      expect(s.has_any_roles?(['one','two','three'])).to be_truthy
    end

    it 'should return true if only some roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'four,five,six'
      })

      expect(s.has_any_roles?(['one','five'])).to be_truthy
    end

    it 'should return false if no roles exist in session' do
      s = Hoodoo::ServiceSession.new({
        :roles => 'four,five,six'
      })

      expect(s.has_any_roles?(['one','two','three'])).to be_falsy
    end
  end
end
