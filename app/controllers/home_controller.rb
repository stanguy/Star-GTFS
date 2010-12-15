class HomeController < ApplicationController
  def show
  end

  def line
    l = Line.find(params[:id])

    headsigns = {}
    l.headsigns.each {|h| headsigns[h.id] = h.name }
    stop_times = {}
    origina_stop_times = StopTime.coming(l.id).order(:arrival)
    origina_stop_times.each do |st|
      stop_times[st.stop_id] = {}
      headsigns.keys.each do|k|
        stop_times[st.stop_id][k] = []
      end
    end
    origina_stop_times.each do |st|
      stop_times[st.stop_id][st.headsign_id] << st
    end
    data = l.stops.collect do|stop|
      stop_info = { :name => stop.name, :id => stop.id, :lat => stop.lat, :lon => stop.lon, :schedule_url => url_for({ :action => 'schedule', :line_id => l.id, :stop_id => stop.id }) }
      if stop_times.has_key? stop.id
        stop_info[:times] = stop_times[stop.id].keys.collect do |headsign_id|
          { 
            :direction => headsigns[headsign_id],
            :times => stop_times[stop.id][headsign_id].collect(&:arrival).map(&:to_formatted_time)
          }
        end.reject {|x| x[:times].empty? }
      end
      stop_info
    end
    render :json => data
  end
  
  def schedule
    @headsigns = {}
    l = Line.find(params[:line_id])
    l.headsigns.each {|h| @headsigns[h.id] = h.name }

    stop_signs = StopTime.where( :line_id => params[:line_id] ).
      where( :stop_id => params[:stop_id] )
    if params[:headsign_id]
      stop_signs = stop_signs.where( :headsign_id => params[:headsign_id] )
    end

    @schedule = {}

    @all_calendars = {}
    stop_signs.each do |st|
      unless @schedule.has_key? st.headsign_id
        @schedule[st.headsign_id] = {}
      end
      ( hours, mins ) = st.arrival.to_hm
      unless @schedule[st.headsign_id].has_key? hours
        @schedule[st.headsign_id][hours] = {}
      end
      unless @schedule[st.headsign_id][hours].has_key? st.calendar
        @schedule[st.headsign_id][hours][st.calendar] = []
        @all_calendars[st.calendar] = 1
      end
      @schedule[st.headsign_id][hours][st.calendar] << mins
    end
    @headsigns.delete_if{|id,v| ! @schedule.has_key? id }
    if request.xhr?
      logger.debug "NO FUCKING LAYOUT"
      render :layout => false and return
    end
  end
      
  
  

end
