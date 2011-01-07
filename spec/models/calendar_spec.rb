
require 'spec_helper'

describe Calendar do 
  describe 'range_to_str' do 
    it 'should output a single day as it short name' do 
      Calendar.range_to_str( Calendar::MONDAY ).should == 'Lu'
      Calendar.range_to_str( Calendar::SATURDAY ).should == 'Sa'
    end
    it 'should output different days as a comma separated list of names' do 
      Calendar.range_to_str( Calendar::MONDAY | Calendar::SATURDAY ).should == 'Lu,Sa'
    end
    it 'should display a range for specific cases' do
      Calendar.range_to_str( Calendar::WEEKDAY ).should == 'Lu-Ve'
    end
  end
end
