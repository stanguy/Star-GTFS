class Dump::PolylinesController < Dump::BaseController
  defaults :resource_class => Polyline
  respond_to :json
  belongs_to :line
end
