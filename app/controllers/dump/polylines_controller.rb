class Dump::PolylinesController < InheritedResources::Base
  defaults :resource_class => Polyline
  respond_to :json
  belongs_to :line
end
