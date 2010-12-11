require 'point'

describe Point do
  it 'should have a constructor with two parameters' do 
    lambda { Point.new }.should raise_error
    lambda { Point.new( 0, 0 ) }.should_not raise_error
  end
  describe 'dist' do
    it 'should have a dist method' do 
      p1 = Point.new( 0, 0 )
      p2 = Point.new( 0, 0 )
      lambda { p1.dist( p2 ) }.should_not raise_error
    end
    it 'should return the distance between two points' do 
      p1 = Point.new( 48.111269, -1.667338 )
      p2 = Point.new( 48.110836, -1.667760 )
      expected_dist = 57.494
      p1.dist( p2 ).floor.should == expected_dist.floor
    end
  end
end
