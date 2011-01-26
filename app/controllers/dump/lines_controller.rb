class Dump::LinesController < InheritedResources::Base
  defaults :resource_class => Line
  respond_to :json

  def bearings
    data = resource.trips.collect do |trip|
      { :id => trip.id, :br => trip.bearing }
    end
    render :json => data
  end

end
