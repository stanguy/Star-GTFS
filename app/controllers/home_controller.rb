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
      stop_info = { :name => stop.name, :id => stop.id, :lat => stop.lat, :lon => stop.lon, :schedule_url => url_for({ :action => 'schedule', :line_id => l.id, :stop_id => stop.id, :only_path => true }) }
      if stop_times.has_key? stop.id
        stop_info[:times] = stop_times[stop.id].keys.collect do |headsign_id|
          { 
            :direction => headsigns[headsign_id],
            :times => stop_times[stop.id][headsign_id].collect(&:arrival).map(&:to_formatted_time),
            :schedule_url => url_for({ :action => 'schedule', :line_id => l.id, :stop_id => stop.id, :headsign_id => headsign_id, :only_path => true })
          }
        end.reject {|x| x[:times].empty? }
      end
      stop_info
    end
    if request.xhr?
      render :json => data
    else
      @line_data = data
      @line_id = l.id
      render :show
    end
  end
  
  def schedule
    @headsigns = {}
    stop_signs = nil
    stop = Stop.find(params[:stop_id])
    @stop_name = stop.name
    if params[:line_id]
      l = Line.find(params[:line_id])
      l.headsigns.each {|h| @headsigns[h.id] = h.name }
      
      stop_signs = StopTime.where( :line_id => params[:line_id] ).
        where( :stop_id => params[:stop_id] )
      if params[:headsign_id]
        stop_signs = stop_signs.where( :headsign_id => params[:headsign_id] )
      end
    else
      @headsigns = {}
      stop.lines.each {|l| 
        l.headsigns.each{|h| 
          r = "^#{l.short_name}"
          logger.debug r
          if h.name.match( Regexp.new(r) )
            @headsigns[h.id] = h.name
          else
            @headsigns[h.id] = "#{l.short_name} #{h.name}"
          end
          logger.debug @headsigns[h.id]
        }
      }
      stop_signs = StopTime.where( :stop_id => stop ).
        where( :line_id => stop.lines )
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
    @schedule.each do |hs_id,hours|
      hours.each do |hour,calendars|
        max_cal = calendars.collect {|cal,mins| mins.count }.max
        calendars.each do|cal,mins|
          if mins.count < max_cal
            mins.fill( '&mdash;'.html_safe, mins.count, max_cal - mins.count )
          end
        end
      end
    end
    @headsigns.delete_if{|id,v| ! @schedule.has_key? id }
    if request.xhr?
      render :layout => false and return
    end
  end    
      
end
