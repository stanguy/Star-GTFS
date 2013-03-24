class Dump::CalendarsController < InheritedResources::Base
  defaults :resource_class => Calendar
  respond_to :json
end
