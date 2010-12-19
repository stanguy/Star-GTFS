
require 'spec_helper'

describe StopTime do
  describe 'coming' do 
    before do
      @line = Factory :line
    end
    it 'should be executed using a line id' do 
      lambda { StopTime.coming }.should raise_error
      lambda { StopTime.coming(@line) }.should_not raise_error
    end
    it 'should not retrieve stop_times before the date' do 
      st_before = Factory :stop_time, { :line => @line, :arrival => 10*60*60, :calendar => Calendar::THURSDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 10:00:00 GMT" ) # 10 GMT => 11 CET
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should_not include st_before
      # st_start_ok = Factory :stop_time, { :arrival => 11*60*60+1 } # 11:01
      # st_start_end = Factory :stop_time, { :arrival => 13*60*60-1 } # 12:59
      # st_after = Factory :stop_time, { :arrival => 14*60*60 }
      # [ st_before, st_start_ok, st_
    end
    it 'should retrieve a stop_time that happen soon' do 
      st = Factory :stop_time, { :line_id => @line.id, :arrival => 11*60*60+1, :calendar => Calendar::THURSDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 10:00:00 GMT" )
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should include st
    end
    it 'should not retrieve a stop_time that happen soon but another day' do 
      st = Factory :stop_time, { :line_id => @line.id, :arrival => 11*60*60+1, :calendar => Calendar::FRIDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 10:00:00 GMT" )
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should_not include st
    end
    it 'should retrieve a stop_time almost 2 hours later' do
      st = Factory :stop_time, { :line_id => @line.id, :arrival => 13*60*60-1, :calendar => Calendar::THURSDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 10:00:00 GMT" )
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should include st     
    end
    it 'should not retrieve a stop_time more than 2 hours later' do
      st = Factory :stop_time, { :line_id => @line.id, :arrival => 13*60*60+1, :calendar => Calendar::THURSDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 10:00:00 GMT" )
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should_not include st
    end
    it 'should retrieve stop_time from the late service' do 
      st = Factory :stop_time, { :line_id => @line.id, :arrival => 25*60*60, :calendar => Calendar::THURSDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 22:30:00 GMT" )
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should include st      
    end
    it 'should retrieve stop_time from the early service' do 
      st = Factory :stop_time, { :line_id => @line.id, :arrival => 30, :calendar => Calendar::FRIDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 22:30:00 GMT" )
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should include st      
    end
    it 'should retrieve stop_time from the late service of the day before' do 
      st = Factory :stop_time, { :line_id => @line.id, :arrival => 30*60*60, :calendar => Calendar::WEDNESDAY } # 10am
      time = Time.httpdate( "Thu, 16 Dec 2010 04:00:00 GMT" )
      Time.zone.should_receive(:now).and_return(time)
      StopTime.coming( @line ).should include st      
    end
  end
end
