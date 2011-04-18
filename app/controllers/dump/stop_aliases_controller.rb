class Dump::StopAliasesController < InheritedResources::Base
  defaults :resource_class => StopAlias 
  respond_to :json
  belongs_to :stop
end
