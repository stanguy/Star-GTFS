require 'spec_helper'

require 'st_lo_importer'

describe StLoImporter do
  describe 'basic data set' do 
    before do 
      @data = [ [ "Stop 1", "", "12:42" ],
                [ "Stop 2", "", "12:43" ] ]
      @importer = StLoImporter.new
      @importer.first_trip_col = 2
      @importer.default_calendar = Calendar::WEEKDAY
      @importer.stops_range = 0..1
      @importer.stop_col = 0
    end
    it 'should parse data without error' do 
      lambda { @importer.import @data }.should_not raise_error
    end
    it 'should return an array' do
      @importer.import(@data).should be_kind_of Array
    end
    it 'should return exactly one trip' do 
      @importer.import(@data).count.should == 1
    end
    it 'should contain a trip with one calendar' do 
      @importer.import(@data)[0].should have_key Calendar::WEEKDAY
    end
    it 'should contain 2 lines for the trip' do 
      @importer.import(@data)[0][Calendar::WEEKDAY].count.should == 2
    end
    it 'should have time and stop id in the first line of the trip' do 
      @importer.import(@data)[0][Calendar::WEEKDAY][0].should be_kind_of Hash
    end
  end
  describe 'Skipping lines' do 
    before do 
      @data = [ [ "Stop 1", "", "12:42" ],
                [ "Stop 2", "", "12:43" ],
                [],
                [ "Stop 3", "", "12:45" ],
                [ "Stop 4", "", "-" ] ]
      @importer = StLoImporter.new
      @importer.first_trip_col = 2
      @importer.default_calendar = Calendar::WEEKDAY
      @importer.stops_range = 0..4
      @importer.stop_col = 0
    end
    it 'should parse data without error' do 
      lambda { @importer.import @data }.should_not raise_error
    end
    it 'should only contain 3 lines' do 
      @importer.import(@data)[0][Calendar::WEEKDAY].count.should == 3
    end
    describe 'simple calendar exception' do 
      before do 
        @importer.add_exception Calendar::WEDNESDAY, [ 3, 2 ]
      end
      it 'should create two calendars for the trip' do 
        trip = @importer.import(@data)[0]
        trip.keys.count.should == 2
        trip.should_not have_key Calendar::WEEKDAY
        trip.should have_key Calendar::WEDNESDAY
      end
      it 'should not add the exception to the main calendar' do 
        @importer.import(@data)[0][Calendar::WEEKDAY ^ Calendar::WEDNESDAY].count.should == 2
      end
      it 'should add the exception to the exception calendar' do 
        @importer.import(@data)[0][Calendar::WEDNESDAY].count.should == 3
      end
    end
    describe 'mixed calendar exception' do 
      before do 
        @importer.add_exception Calendar::WEDNESDAY, [ 1, 2 ]
      end
      it 'should not add the exception to the main calendar' do 
        @importer.import(@data)[0][Calendar::WEEKDAY ^ Calendar::WEDNESDAY].count.should == 2
      end
      it 'should add the exception to the exception calendar' do 
        @importer.import(@data)[0][Calendar::WEDNESDAY].count.should == 3
      end
    end
    describe 'ranged calendar exception' do 
      before do 
        @importer.add_exception Calendar::WEDNESDAY, [ 0..1, 2 ]
      end
      it 'should not add the exception to the main calendar' do 
        @importer.import(@data)[0][Calendar::WEEKDAY ^ Calendar::WEDNESDAY].count.should == 1
      end
      it 'should add the exception to the exception calendar' do 
        @importer.import(@data)[0][Calendar::WEDNESDAY].count.should == 3
      end
    end
  end
end
