# The X-Assume-Identity-Of secured HTTP header allows a caller to
# masquerade as some other identity according to scoping limitations.
# Since this bypasses some of the deliberate restrictions on identity
# through a Caller, it's important to test it extensively so this
# file exists for that purpose alone.
#
# The inter-resource local and remote specs are also involved to make
# sure that the header value is auto-propagated across inter-resource
# calls. This is obviously vital, else the identity of a caller may
# seem to change across the inter-resource boundary.

require 'spec_helper'

# ============================================================================

class RSpecAssumedIdentityImplementation < Hoodoo::Services::Implementation

  # This implementation returns the identity hash from the Hoodoo session
  # information under the body data key of "identity". If there is a
  # "caller_id" key present in the Hoodoo identity is it removed first.
  #
  def show( context )
    identity_hash = Hoodoo::Utilities.stringify( context.session.identity.to_h )
    identity_hash.delete( 'caller_id' )

    context.response.body = {
      'identity' => identity_hash
    }
  end
end

class RSpecAssumedIdentityInterface < Hoodoo::Services::Interface
  interface :RSpecAssumedIdentity do
    endpoint :rspec_assumed_identity, RSpecAssumedIdentityImplementation
    actions :show
  end
end

class RSpecAssumedIdentityService < Hoodoo::Services::Service
  comprised_of RSpecAssumedIdentityInterface
end

# ============================================================================

describe Hoodoo::Services::Middleware do

  before :each do
    @old_test_session = Hoodoo::Services::Middleware.test_session()

    # Set up a permissive test session that's ready to have scoping and
    # identity information updated.
    #
    @test_session = @old_test_session.dup

    permissions = Hoodoo::Services::Permissions.new # (this is "default-else-deny")
    permissions.set_default_fallback( Hoodoo::Services::Permissions::ALLOW )

    @test_session.permissions = permissions
    @test_session.identity    = OpenStruct.new
    @test_session.scoping     = @test_session.scoping.dup
  end

  after :each do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run RSpecAssumedIdentityService.new
    end
  end

  # Calls the test service using a given identity Hash (which it encodes
  # for the HTTP header) and expecting the given HTTP status code (as a
  # String or Integer). If expecting 200, the response from the test
  # service is examined as the "identity" key in the response body should
  # yield the same identity hash that was given on input, if the
  # middleware correctly decoded and transferred the encoded value all
  # the way through to the called service.
  #
  # +identity_hash+::   Hash for the 'assume identity' header, String keys
  #                     and values only
  #
  # +expected_status+:: HTTP status to expect(), as a String or Integer.
  #
  # Always returns the JSON-parsed response body for further examination.
  #
  def show( identity_hash, expected_status )
    get(
      '/v1/rspec_assumed_identity/hello',
      nil,
      {
        'CONTENT_TYPE'              => 'application/json; charset=utf-8',
        'HTTP_X_ASSUME_IDENTITY_OF' => URI.encode_www_form( identity_hash )
      }
    )

    expect( last_response.status ).to eq( expected_status )
    result = JSON.parse( last_response.body )

    if ( expected_status == 200 )
      expect( result[ 'identity' ] ).to eq( identity_hash )
    end

    return result
  end

  # ==========================================================================

  # Tested implicitly elsewhere and explicitly here to make sure.
  #
  context 'X-Assume-Identity-Of prohibited' do
    before :each do
      @test_session.scoping.authorised_http_headers = []
      Hoodoo::Services::Middleware.set_test_session( @test_session )
    end

    it 'rejects usage attempts' do
      result = show( { 'account_id' => 'bad' }, 403 )

      # We expect a generic - arguably even confusing - 'platform.forbidden'
      # message to avoid information disclosure that someone has guessed /
      # potentially correctly tried to use a secured header, but for their
      # caller credentials prohibiting its use.
      #
      expect( result[ 'kind' ] ).to eq( 'Errors' )
      expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
      expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'Action not authorized' )
    end
  end

  # ==========================================================================

  context 'X-Assume-Identity-Of allowed' do
    context 'with empty rules' do
      before :each do
        @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
        @test_session.scoping.authorised_identities   = {}

        Hoodoo::Services::Middleware.set_test_session( @test_session )
      end

      it 'rejects any values' do
        result = show( { 'account_id' => '1', 'member_id' => 1 }, 403 )

        expect( result[ 'kind' ] ).to eq( 'Errors' )
        expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
        expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
        expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id\\,member_id' )
      end
    end

    context 'with flat rules' do
      context 'and no wildcards' do
        before :each do
          @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
          @test_session.scoping.authorised_identities   =
          {
            'account_id' => [ '20', '21', '22' ],
            'member_id'  => [ '1', '2', '3', '4', '5', '6' ],
            'device_id'  => [ 'A', 'B' ]
          }

          Hoodoo::Services::Middleware.set_test_session( @test_session )
        end

        it 'rejects bad account ID' do
          result = show( { 'account_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id,bad' )
        end

        it 'rejects bad member ID' do
          result = show( { 'member_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id,bad' )
        end

        it 'rejects bad device ID' do
          result = show( { 'device_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'device_id,bad' )
        end

        # Belt-and-braces check that multiple bad items are still rejected,
        # but don't have any expectations about which one gets picked out
        # in the 'reference' field.
        #
        it 'rejects bad combinations' do
          result = show( { 'account_id' => 'bad', 'member_id' => 'bad', 'device_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'    ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
        end

        it 'rejects bad IDs amongst good' do
          result = show( { 'account_id' => '21', 'member_id' => 'bad', 'device_id' => 'A' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id,bad' )
        end

        # Each 'show' must be in its own test so that the test session data
        # gets reset in between; otherwise, the *same* session identity is
        # being successively merged/updated under test, since it's a single
        # object that's reused rather than a new loaded-in session.
        #
        it 'accepts one good ID (1)' do
          result = show( { 'account_id' => '22' }, 200 )
        end
        it 'accepts one good ID (2)' do
          result = show( { 'member_id'  => '1'  }, 200 )
        end
        it 'accepts one good ID (3)' do
          result = show( { 'device_id'  => 'B'  }, 200 )
        end
        it 'accepts many good IDs' do
          result = show( { 'account_id' => '22', 'member_id' => '1', 'device_id' => 'B' }, 200 )
        end

        it 'accepts encoded names' do
          get(
            '/v1/rspec_assumed_identity/hello',
            nil,
            {
              'CONTENT_TYPE'              => 'application/json; charset=utf-8',
              'HTTP_X_ASSUME_IDENTITY_OF' => 'a%63%63ount_id=22'
            }
          )

          expect( last_response.status ).to eq( 200 )
        end

        it 'accepts encoded values' do
          get(
            '/v1/rspec_assumed_identity/hello',
            nil,
            {
              'CONTENT_TYPE'              => 'application/json; charset=utf-8',
              'HTTP_X_ASSUME_IDENTITY_OF' => 'account_id=%32%32'
            }
          )

          expect( last_response.status ).to eq( 200 )
        end

        it 'rejects an unknown name' do
          result = show( { 'another_id' => 'A155C' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'another_id' )
        end

        it 'rejects unknown names' do
          result = show( { 'another_id' => 'A155C', 'additional_id' => 'iiv' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'additional_id\\,another_id' )
        end

        it 'rejects an unknown name amongst a known name' do
          result = show( { 'another_id' => 'A155C', 'account_id' => '22' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'another_id' )
        end

        it 'rejects an unknown name amongst known names' do
          result = show( { 'another_id' => 'A155C', 'account_id' => '22', 'member_id' => '1' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'another_id' )
        end
      end

      context 'and wildcards' do
        before :each do
          @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
          @test_session.scoping.authorised_identities   =
          {
            'account_id' => [ '20', '21', '22' ],
            'member_id'  => '*',
            'device_id'  => [ 'A', 'B' ]
          }

          Hoodoo::Services::Middleware.set_test_session( @test_session )
        end

        it 'rejects bad account ID' do
          result = show( { 'account_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id,bad' )
        end

        it 'rejects bad device ID' do
          result = show( { 'device_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'device_id,bad' )
        end

        it 'rejects bad combinations' do
          result = show( { 'account_id' => 'bad', 'member_id' => 'hit_wildcard', 'device_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'    ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
        end

        it 'rejects bad IDs amongst good' do
          result = show( { 'account_id' => '21', 'member_id' => 'hit_wildcard', 'device_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'device_id,bad' )
        end

        it 'accepts wildcard combinations' do
          result = show( { 'account_id' => '21', 'member_id' => 'hit_wildcard', 'device_id' => 'A' }, 200 )
        end

        it 'accepts one good ID (1)' do
          result = show( { 'account_id' => '22' }, 200 )
        end
        it 'accepts one good ID (2)' do
          result = show( { 'member_id'  => 'hit_wildcard'  }, 200 )
        end
        it 'accepts one good ID (3)' do
          result = show( { 'device_id'  => 'B'  }, 200 )
        end
        it 'accepts many good IDs' do
          result = show( { 'account_id' => '22', 'member_id' => '1', 'device_id' => 'B' }, 200 )
        end
      end
    end

    context 'with deep rules' do
      context 'and no wildcards' do
        before :each do
          @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
          @test_session.scoping.authorised_identities   =
          {
            'account_id' =>
            {
              '20' => { 'member_id' => [ '1', '2' ] },
              '21' => { 'member_id' => [ '3', '4' ] },
              '22' =>
              {
                'member_id' =>
                {
                  '5' => { 'device_id' => [ 'A' ] },
                  '6' => { 'device_id' => [ 'B' ] }
                }
              }
            }
          }

          Hoodoo::Services::Middleware.set_test_session( @test_session )
        end

        it 'rejects bad account ID' do
          result = show( { 'account_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id,bad' )
        end

        it 'rejects bad member ID' do
          result = show( { 'account_id' => '20', 'member_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id,bad' )
        end

        it 'rejects bad device ID' do
          result = show( { 'account_id' => '22', 'member_id' => '5', 'device_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'device_id,bad' )
        end

        it 'rejects attempt to use device ID when not listed in rules' do
          result = show( { 'account_id' => '21', 'member_id' => '4', 'device_id' => 'A' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'device_id' )
        end

        it 'rejects an ID that is present but listed under a different key' do
          result = show( { 'account_id' => '20', 'member_id' => '4' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id,4' )
        end

        it 'rejects an ID that is present but not top-level' do
          result = show( { 'member_id' => '1' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id' )
        end

        it 'accepts a subset of good IDs (1)' do
          result = show( { 'account_id' => '22' }, 200 )
        end
        it 'accepts a subset of good IDs (2)' do
          result = show( { 'account_id' => '22', 'member_id' => '5' }, 200 )
        end
        it 'accepts many good IDs (1)' do
          result = show( { 'account_id' => '20', 'member_id' => '2' }, 200 )
        end
        it 'accepts many good IDs (2)' do
          result = show( { 'account_id' => '22', 'member_id' => '6', 'device_id' => 'B' }, 200 )
        end

        it 'rejects an unknown name' do
          result = show( { 'another_id' => 'A155C' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'another_id' )
        end

        it 'rejects unknown names' do
          result = show( { 'another_id' => 'A155C', 'additional_id' => 'iiv' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'additional_id\\,another_id' )
        end

        it 'rejects an unknown name amongst a known name' do
          result = show( { 'another_id' => 'A155C', 'account_id' => '22' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'another_id' )
        end

        it 'rejects an unknown name amongst known names' do
          result = show( { 'another_id' => 'A155C', 'account_id' => '22', 'member_id' => '6' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'another_id' )
        end
      end

      context 'and wildcards' do
        before :each do
          @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
          @test_session.scoping.authorised_identities   =
          {
            'account_id' =>
            {
              '20' => { 'member_id' => [ '1', '2' ] },
              '21' => { 'member_id' => '*' },
              '22' =>
              {
                'member_id' =>
                {
                  '5' => { 'device_id' => [ 'A' ] },
                  '6' => { 'device_id' => [ 'B' ] }
                }
              }
            }
          }

          Hoodoo::Services::Middleware.set_test_session( @test_session )
        end

        it 'rejects bad account ID' do
          result = show( { 'account_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id,bad' )
        end

        it 'rejects bad member ID' do
          result = show( { 'account_id' => '20', 'member_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id,bad' )
        end

        it 'rejects bad device ID' do
          result = show( { 'account_id' => '22', 'member_id' => '5', 'device_id' => 'bad' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'device_id,bad' )
        end

        it 'rejects attempt to use device ID when not listed in rules' do
          result = show( { 'account_id' => '21', 'member_id' => '4', 'device_id' => 'A' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'device_id' )
        end

        it 'rejects an ID that is present but listed under a different key' do
          result = show( { 'account_id' => '20', 'member_id' => '4' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id,4' )
        end

        it 'rejects an ID that is present but not top-level' do
          result = show( { 'member_id' => '1' }, 403 )

          expect( result[ 'kind' ] ).to eq( 'Errors' )
          expect( result[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
          expect( result[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'X-Assume-Identity-Of header value requests prohibited identity name(s)' )
          expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'member_id' )
        end

        it 'accepts a subset of good IDs (1)' do
          result = show( { 'account_id' => '22' }, 200 )
        end
        it 'accepts a subset of good IDs (2)' do
          result = show( { 'account_id' => '22', 'member_id' => '5' }, 200 )
        end
        it 'accepts many good IDs (1)' do
          result = show( { 'account_id' => '20', 'member_id' => '2' }, 200 )
        end
        it 'accepts many good IDs (2)' do
          result = show( { 'account_id' => '22', 'member_id' => '6', 'device_id' => 'B' }, 200 )
        end
        it 'accepts wildcard names' do
          result = show( { 'account_id' => '21', 'member_id' => 'hit_wildcard' }, 200 )
        end
      end
    end

    context 'with malformed rules' do
      def set_rules( rules )
        @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
        @test_session.scoping.authorised_identities   = rules
        Hoodoo::Services::Middleware.set_test_session( @test_session )
      end

      def expect_malformed( result )
        expect( result[ 'kind' ] ).to eq( 'Errors' )
        expect( result[ 'errors' ][ 0 ][ 'code'    ] ).to eq( 'generic.malformed' )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( "X-Assume-Identity-Of header cannot be processed because of malformed scoping rules in Session's associated Caller" )
      end

      it 'rejects top-level non-Hash (1)' do
        set_rules( [ '1', '2', '3' ] )
        result = show( { 'account_id' => '21' }, 422 )
        expect_malformed( result )
      end

      it 'rejects top-level non-Hash (2)' do
        set_rules( 'String' )
        result = show( { 'account_id' => '21' }, 422 )
        expect_malformed( result )
      end

      it 'rejects top-level value where array was expected' do
        set_rules( {
          'account_id' => '21'
        } )

        result = show( { 'account_id' => '21' }, 422 )
        expect_malformed( result )
      end

      it 'rejects intermediate value where Hash was expected' do
        set_rules( {
          'account_id' =>
          {
            '20' => 'member_id'
          }
        } )

        result = show( { 'account_id' => '20', 'member_id' => '1' }, 422 )
        expect_malformed( result )
      end

      it 'rejects deep value where Array was expected' do
        set_rules( {
          'account_id' =>
          {
            '22' =>
            {
              'member_id' =>
              {
                '5' => { 'device_id' => 'A' }
              }
            }
          }
        } )

        result = show( { 'account_id' => '22', 'member_id' => '5', 'device_id' => 'A' }, 422 )
        expect_malformed( result )
      end
    end

    # All of these should result in 403 cases because they parse into
    # identity hashes with either an empty key or empty value, or a
    # key or value that's not allowed by the rules. The exception is
    # for the pure empty string header value or empty Hash, which
    # gets caught explicitly as malformed input.
    #
    context 'but header value is malformed' do
      before :each do
        @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
        @test_session.scoping.authorised_identities   =
        {
          'account_id' => [ '20', '21', '22' ],
          'member_id'  => [ '1', '2', '3', '4', '5', '6' ],
          'device_id'  => [ 'A', 'B' ]
        }

        Hoodoo::Services::Middleware.set_test_session( @test_session )
      end

      it 'rejects explicit empty hashes (1)' do
        get(
          '/v1/rspec_assumed_identity/hello',
          nil,
          {
            'CONTENT_TYPE'              => 'application/json; charset=utf-8',
            'HTTP_X_ASSUME_IDENTITY_OF' => ''
          }
        )

        expect( last_response.status ).to eq( 422 )
      end

      # Likewise via a Hash.
      #
      it 'rejects explicit empty hashes (2)' do
        result = show( {}, 422 )
      end

      it 'rejects no-key headers (1)' do
        get(
          '/v1/rspec_assumed_identity/hello',
          nil,
          {
            'CONTENT_TYPE'              => 'application/json; charset=utf-8',
            'HTTP_X_ASSUME_IDENTITY_OF' => '=22'
          }
        )

        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( '' )
      end

      # Likewise via a Hash.
      #
      it 'rejects no-key headers (2)' do
        result = show( { '' => '22' }, 403 )
      end

      it 'rejects no-key value (1)' do
        get(
          '/v1/rspec_assumed_identity/hello',
          nil,
          {
            'CONTENT_TYPE'              => 'application/json; charset=utf-8',
            'HTTP_X_ASSUME_IDENTITY_OF' => 'account_id='
          }
        )

        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id,' )
      end

      # Likewise via a Hash.
      #
      it 'rejects no-key value (2)' do
        result = show( { 'account_id' => '' }, 403 )
      end

      it 'rejects a non-KVP value' do
        get(
          '/v1/rspec_assumed_identity/hello',
          nil,
          {
            'CONTENT_TYPE'              => 'application/json; charset=utf-8',
            'HTTP_X_ASSUME_IDENTITY_OF' => 'foo'
          }
        )

        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'foo' )
      end

      it 'rejects a badly encoded value' do
        get(
          '/v1/rspec_assumed_identity/hello',
          nil,
          {
            'CONTENT_TYPE'              => 'application/json; charset=utf-8',
            'HTTP_X_ASSUME_IDENTITY_OF' => 'account_id=%4'
          }
        )

        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id,%4' )
      end

      it 'rejects an encoded "=" because it is taken as a literal, not a separator' do
        get(
          '/v1/rspec_assumed_identity/hello',
          nil,
          {
            'CONTENT_TYPE'              => 'application/json; charset=utf-8',
            'HTTP_X_ASSUME_IDENTITY_OF' => 'account_id%3d22'
          }
        )

        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'account_id=22' )
      end
    end
  end

  # ==========================================================================

  context 'code coverage' do
    before :each do
      @test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
      @test_session.scoping.authorised_identities   = { 'account_id' => [ '1' ] }
      Hoodoo::Services::Middleware.set_test_session( @test_session )
    end

    it 'internally self-checks' do
      allow_any_instance_of( Hoodoo::Services::Middleware ).to receive( :deal_with_x_assume_identity_of ) do | instance, interaction |
        instance.send(
          :validate_x_assume_identity_of,
          interaction,
          { 'account_id' => 23 },
          @test_session.scoping.authorised_identities
        )
      end

      result = show( { 'account_id' => '1' }, 500 )
      expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Internal error - internal validation input value for X-Assume-Identity-Of is not a String' )
    end
  end

end
