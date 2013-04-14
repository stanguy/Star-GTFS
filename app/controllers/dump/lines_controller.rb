class Dump::LinesController < Dump::BaseController
  defaults :resource_class => Line
  respond_to :json
  belongs_to :agency

  def bearings
    data = resource.trips.collect do |trip|
      { :id => trip.id, :br => trip.bearing }
    end
    render :json => data
  end

end
