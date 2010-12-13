class HomeController < ApplicationController
  def show
  end

  def line
    l = Line.find(params[:id])
    headsigns = {}
    l.trips.of_the_day.each { |t| headsigns[t.id] = t.headsign.to_sym }
    stop_times = {}
    original_stop_times = StopTime.coming(l.id).order(:arrival)
    trip_names = original_stop_times.collect(&:trip_id).map{|tid| headsigns[tid] }.uniq
    l.stops.select('id').each do |stop|
      sid = stop.id
      stop_times[sid] = {}
      trip_names.each do |tname|
        stop_times[sid][tname] = []
      end
    end
    original_stop_times.each do |st|
      stop_times[st.stop_id][headsigns[st.trip_id]] << st
    end
    data = l.stops.collect do|stop|
      stop_info = { :name => stop.stop_name, :id => stop.id, :lat => stop.lat, :lon => stop.lon }
      if stop_times.has_key? stop.id
        stop_info[:times] = stop_times[stop.id].keys.collect do |trip_name|
          { 
            :direction => trip_name,
            :times => stop_times[stop.id][trip_name].collect(&:arrival).map(&:to_formatted_time)
          }
        end.reject {|x| x[:times].empty? }
      end
      stop_info
    end
    render :json => data
  end

  def stop
    line_id = params[:line]
    stop_id = params[:stop]
    now = Time.now
    sts = StopTime.coming(line_id,stop_id).limit( 10 )
    jsts = sts.collect do|stop_time|
      { :time => stop_time.arrival.to_formatted_time,
        :direction => stop_time.trip.headsign }
    end
    render :json => jsts
  end
      

end
