class Dump::StopTimesController < Dump::BaseController
  def index
    render :json => StopTime.where( :stop_id => params[:stop_id], :line_id => params[:line_id] )
  end
end
