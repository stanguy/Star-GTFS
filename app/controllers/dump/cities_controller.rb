class Dump::CitiesController < Dump::BaseController
  defaults :resource_class => City
  respond_to :json
end
