require 'spec_helper'

describe ApiTools::ServiceContext do

  # TODO: Not much to test yet.

  it 'should initialise correctly' do
    ses = ApiTools::ServiceSession.new
    req = ApiTools::ServiceRequest.new
    res = ApiTools::ServiceResponse.new
    con = ApiTools::ServiceContext.new( ses, req, res )

    expect(con.session).to eq(ses)
    expect(con.request).to eq(req)
    expect(con.response).to eq(res)
  end
end
