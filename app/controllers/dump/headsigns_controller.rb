class Dump::HeadsignsController < Dump::BaseController
  defaults :resource_class => Headsign
  respond_to :json
  belongs_to :line
end
