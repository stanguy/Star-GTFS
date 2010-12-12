class HomeController < ApplicationController
  def show
  end

  def line
    l = Line.find(params[:id])
    headsigns = {}
    l.trips.of_the_day.each { |t| headsigns[t.id] = t.headsign }
    stop_times = {}
    StopTime.coming(l.id).order(:arrival).each do |st|
      unless stop_times.has_key? st.stop_id
        stop_times[st.stop_id] = Array.new
      end
      stop_times[st.stop_id] << st
    end
    data = l.stops.collect do|stop|
      stop_info = { :name => stop.stop_name, :id => stop.id, :lat => stop.lat, :lon => stop.lon }
      if stop_times.has_key? stop.id
        stop_info[:times] = stop_times[stop.id].collect do |st|
          {
            :time => st.arrival.to_formatted_time,
            :direction => headsigns[st.trip_id]
          }
        end
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
