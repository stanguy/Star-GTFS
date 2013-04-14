class Dump::CalendarsController < Dump::BaseController
  defaults :resource_class => Calendar
  respond_to :json
end
