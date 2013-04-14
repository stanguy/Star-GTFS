class Dump::CalendarDatesController < Dump::BaseController
  defaults :resource_class => CalendarDate
  respond_to :json
end
