class Dump::CitiesController < InheritedResources::Base
  defaults :resource_class => City
  respond_to :json
end
