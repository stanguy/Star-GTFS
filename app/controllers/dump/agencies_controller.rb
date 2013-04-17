class Dump::AgenciesController < InheritedResources::Base
  defaults :resource_class => Agency
  respond_to :json
end
