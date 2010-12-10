require 'point'

describe Point do
  it 'should have a constructor with two parameters' do 
    lambda { Point.new }.should raise_error
    lambda { Point.new( 0, 0 ) }.should_not raise_error
  end
  describe 'dist' do
    it 'should have a dist method'
    it 'should return the distance between two points'
  end
end
