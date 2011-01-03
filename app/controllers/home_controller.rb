class HomeController < ApplicationController
  def show
  end

  def stops
    @stops = true
    render :show
  end

  def line
    l = Line.find(params[:id])

    if params[:stop_id]
      @selected_stop = params[:stop_id]
    end

    headsigns = {}
    l.headsigns.each {|h| headsigns[h.id] = h.name }
    stop_times = {}
    bearings = {}
    original_stop_times = StopTime.coming(l.id).includes(:trip).order(:arrival)
    original_stop_times.each do |st|
      stop_times[st.stop_id] = {}
      headsigns.keys.each do|k|
        stop_times[st.stop_id][k] = []
      end
    end
    original_stop_times.each do |st|
      stop_times[st.stop_id][st.headsign_id] << st
      unless bearings.has_key? st.headsign_id
        bearings[st.headsign_id] = st.trip.bearing
      end
    end
    
    other_lines = {}
    Line.
      select( "id,short_name").
      where( :id => l.stops.collect(&:line_ids_cache).
                      map {|ids| ids.split(',') }.flatten.uniq ).each { |vl| other_lines[vl.id] = vl.short_name }
    data = l.stops.collect do|stop|
      stop_info = {
        :name => stop.name,
        :id => stop.id, :lat => stop.lat, :lon => stop.lon,
        :schedule_url => url_for({ :action => 'schedule', :line_id => l.id, :stop_id => stop.id, :only_path => true })
      }
      stop_info[:others] = stop.line_ids_cache.split(',').delete_if{|olid| olid.to_i == l.id }.collect{|olid|
        { :id => olid, :name => other_lines[olid.to_i] }
      }.compact
      if stop_times.has_key? stop.id
        stop_info[:times] = stop_times[stop.id].keys.collect do |headsign_id|
          {
            :direction => headsigns[headsign_id],
            :bearing => bearings[headsign_id],
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
    @stop_id = stop.id
    @other_lines = nil
    if params[:line_id]
      l = Line.find(params[:line_id])
      l.headsigns.each {|h| 
          if h.name.match( Regexp.new( "^#{l.short_name} " ) )
            @headsigns[h.id] = h.name
          else
            @headsigns[h.id] = "#{l.short_name} vers #{h.name}"
          end
      }

      stop_signs = StopTime.where( :line_id => params[:line_id] ).
        where( :stop_id => params[:stop_id] )
      if params[:headsign_id]
        stop_signs = stop_signs.where( :headsign_id => params[:headsign_id] )
      end
      @other_lines = stop.lines.select( "id,short_name").collect{|sl|
        if sl.id != l.id
          { :id => sl.id, :name => sl.short_name }
        end
      }.compact
    else
      @headsigns = {}
      stop.lines.each {|l|
        l.headsigns.each{|h|
          if h.name.match( Regexp.new( "^#{l.short_name} " ) )
            @headsigns[h.id] = h.name
          else
            @headsigns[h.id] = "#{l.short_name} vers #{h.name}"
          end
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
        @all_calendars[st.headsign_id] = {}
      end
      ( hours, mins ) = st.arrival.to_hm false
      unless @schedule[st.headsign_id].has_key? hours
        @schedule[st.headsign_id][hours] = {}
      end
      unless @schedule[st.headsign_id][hours].has_key? st.calendar
        @schedule[st.headsign_id][hours][st.calendar] = []
        @all_calendars[st.headsign_id][st.calendar] = 1
      end
      @schedule[st.headsign_id][hours][st.calendar] << mins
    end
    @headsigns.delete_if{|id,v| ! @schedule.has_key? id }
    if request.xhr?
      render :layout => false and return
    end
  end
end
