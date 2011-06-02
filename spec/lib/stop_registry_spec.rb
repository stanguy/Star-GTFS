require 'spec_helper'
require 'stop_registry'

describe StopRegistry do 
  before do 
    @reg = StopRegistry.new
  end
  it 'should allow registering a stop through the [] operator' do 
    lambda { @reg['Stop 1'] }.should_not raise_error
  end
  it 'should create a new Stop object' do 
    @reg['Stop 1'].should be_kind_of Stop
  end
  it 'should create the same stop if the same name is provided multiple times' do 
    @reg['Stop 1'].should == @reg['Stop 1']
  end
  it 'should remove unwanted characters' do 
    @reg['Stop 1***'].name.should == 'Stop 1'
  end
end
