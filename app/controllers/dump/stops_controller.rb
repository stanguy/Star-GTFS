class Dump::StopsController < InheritedResources::Base
  defaults :resource_class => Stop
  respond_to :json
  belongs_to :line

  def main_ids
    data = Stop.all.collect do |stop|
      [ stop.id, stop.stop_aliases.order( 'src_id ASC' ).first.src_id ]
    end
    render :json => data
  end
end
