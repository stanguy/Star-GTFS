class Dump::AgenciesController < Dump::BaseController
  defaults :resource_class => Agency
  respond_to :json
end
