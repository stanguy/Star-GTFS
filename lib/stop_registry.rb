
class StopRegistry
  def initialize
    @reg = {}
  end

  def clean_up str
    str.gsub( /\*/, '' )
  end
      
      
  def []( stop_name )
    stop_name = clean_up( stop_name )
    unless @reg.has_key? stop_name
      @reg[stop_name] = Stop.create( :name => stop_name )
    end
    @reg[stop_name]
  end    
end
