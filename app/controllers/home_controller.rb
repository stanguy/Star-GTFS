class HomeController < ApplicationController
  def show
  end

  def line
    l = Line.find(params[:id])
    data = l.stops.collect do|stop|
      { :name => stop.stop_name, :id => stop.id, :lat => stop.lat, :lon => stop.lon,
        :times => StopTime.coming(l.id,stop.id).includes(:trip).limit( 10 ).collect {|st|
          {
            :time => st.arrival.to_formatted_time,
            :direction => st.trip.headsign
          }
        }
      }
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
