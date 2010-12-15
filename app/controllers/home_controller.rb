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
      stop_info = { :name => stop.name, :id => stop.id, :lat => stop.lat, :lon => stop.lon }
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
end
