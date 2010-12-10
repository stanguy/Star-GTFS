class HomeController < ApplicationController
  def show
  end

  def line
    l = Line.find(params[:id])
    data = l.stops.collect do|stop|
      { :name => stop.stop_name, :id => stop.id, :lat => stop.lat, :lon => stop.lon }
    end
    render :json => data
  end

  def stop
    line_id = params[:line]
    stop_id = params[:stop]
    now = Time.now
    sts = StopTime.where( :line_id => line_id, :stop_id => stop_id ).
      where( "calendar & ? > 0", Calendar.from_time( now ) ).
      where( "arrival > ?", ( now.hour * 60 + now.min ) * 60 + now.sec ).
      order( "arrival asc" ).limit( 10 )
    jsts = sts.collect do|stop_time|
      { :time => stop_time.arrival }
    end
    render :json => jsts
  end
      

end
