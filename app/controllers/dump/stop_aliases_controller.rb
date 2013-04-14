class Dump::StopAliasesController < Dump::BaseController
  defaults :resource_class => StopAlias 
  respond_to :json
  belongs_to :stop
end
