class Dump::StopsController < InheritedResources::Base
  defaults :resource_class => Stop
  respond_to :json
  belongs_to :line
end
