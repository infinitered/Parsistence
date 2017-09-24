describe 'Parse Model' do
  # before do
  #   @model = TestModel.new
  # end
  def test_model
    @model ||= TestModel.new
  end

  it 'Check if the model is valid' do
    test_model.respond_to?('PFObject').should == true
  end

  it 'Should be able to retrieve a list of fields' do
    fields = test_model.fields
    fields.should.be.kind_of?(Array)
    fields.length.should.not == 0
  end

  it 'Should be able to retrieve a list of relations' do
    relations = test_model.relations
    relations.should.be.kind_of?(Array)
  end

  it 'Should allow setting a field' do
    test_model.name = 'Parsistence'
    test_model.name.should == 'Parsistence'
  end
end
