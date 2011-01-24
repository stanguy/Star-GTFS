class Dump::HeadsignsController < InheritedResources::Base
  defaults :resource_class => Headsign
  respond_to :json
  belongs_to :line
end
