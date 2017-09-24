describe 'Parse SDK' do
  it 'Can find the Parse App ID and Client Key' do
    app_id = ENV['PARSE_APPLICATION_ID']
    client_key = ENV['PARSE_CLIENT_KEY']
    app_id.should.not == nil
    client_key.should.not == nil
  end

  it 'Can initialize Parse with App ID and Client Key ' do
    Parse.setApplicationId(ENV['PARSE_APPLICATION_ID'], clientKey: ENV['PARSE_CLIENT_KEY'])
    app_id = Parse.getApplicationId
    client_key = Parse.getClientKey
    app_id.should == ENV['PARSE_APPLICATION_ID']
    client_key.should == ENV['PARSE_CLIENT_KEY']
  end

end
