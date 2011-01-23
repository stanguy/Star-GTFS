class Dump::LinesController < InheritedResources::Base
  defaults :resource_class => Line
  respond_to :json
end
