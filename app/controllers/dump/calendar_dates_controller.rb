class Dump::CalendarDatesController < InheritedResources::Base
  defaults :resource_class => CalendarDate
  respond_to :json
end
