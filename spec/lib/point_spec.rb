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
  describe 'bearing' do
    it 'should be a method' do
      p1 = Point.new( 0, 0 )
      p2 = Point.new( 1, 0 )
      lambda { p1.bearing( p2 ) }.should_not raise_error
    end
    def test_bearing( h1, h2 )
      p1 = Point.new( h1[:y], h1[:x] )
      p2 = Point.new( h2[:y], h2[:x] )
      p1.bearing( p2 )
    end
    it 'should return nil if the point is the same' do
      lambda{ test_bearing( { :x =>  -1.620755, :y =>  48.114116 }, { :x =>  -1.620755, :y =>  48.114116 } ) }.should_not raise_error
      test_bearing( { :x =>  -1.620755, :y =>  48.114116 }, { :x =>  -1.620755, :y =>  48.114116 } ).should be_nil
    end
      
    
    it "should find a simple 90 angle" do
        test_bearing( { :x => 0, :y => 0 }, { :x => 1, :y => 0 } ).should == 90
    end
    it "should find a simple flat" do
        test_bearing( { :x => 0, :y => 0 }, { :x => 0, :y => 1 } ).should == 0
    end
    it "simple 45 deg" do
        test_bearing( { :x => 0, :y => 0 }, { :x => 1, :y => 1 } ).round.should == 45
    end
    it "real to the right" do
        test_bearing( { :x =>  -1.620755, :y =>  48.114116 }, { :x => -1.617381, :y => 48.114116 } ).round.should == 90
    end
    it "real to the left" do
        test_bearing( { :x => -1.617381, :y => 48.114116 }, { :x =>  -1.620755, :y =>  48.114116 } ).round.should == -90
    end
    it "real top right" do
        # right, top
        test_bearing( { :x =>  -1.620755, :y =>  48.114116 }, { :x => -1.618786, :y => 48.115401} ).floor.should == 45
    end
    it "real top left" do
        # left up
        test_bearing( { :x =>  -1.620755, :y =>  48.114116 }, { :x => -1.622724, :y => 48.115401} ).ceil.should == -45
    end
    it "real right bottom" do
        # right, bottom
        test_bearing( { :x =>  -1.620755, :y =>  48.114116 }, { :x => -1.618786, :y => 48.112800} ).round.should == 90+45
    end
    it "real bottom left" do
        # left bottom
        test_bearing( { :x =>  -1.620755, :y =>  48.114116 }, { :x => -1.622724, :y => 48.112800} ).round.should == -(90+45)
    end
    
    
  end
end
