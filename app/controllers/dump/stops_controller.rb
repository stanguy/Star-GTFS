class Dump::StopsController < InheritedResources::Base
  defaults :resource_class => Stop
  respond_to :json
  belongs_to :line, :optional => true

  def main_ids
    data = Stop.all.collect do |stop|
      stop_alias = stop.stop_aliases.order( 'src_id ASC' ).first
      [ stop.id, stop_alias.src_id, stop_alias.old_src_id ]
    end
    render :json => data
  end
  def close
    neighbours = {}
    { :bike => BikeStation, :metro => MetroStation, :pos => Pos }.each do |k,klass|
      neighbours[k] = klass.close_to( resource.geom, 1000 ).limit( 10 ).collect {|o|
        { :id => o.id, :name => o.name, :address => o.address,
          :lat => o.lat, :lon => o.lon,
          :distance => o.distance.to_i } 
      }
    end
    render :json => neighbours
  end
end
