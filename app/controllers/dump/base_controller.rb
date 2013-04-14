class Dump::BaseController < InheritedResources::Base
  before_filter :set_agency

  private
    def set_agency
    if params[:agency_id]
      @agency = Agency.find( params[:agency_id] )
      if @agency.nil?
        not_found
      end
      Apartment::Database.switch( @agency.db_slug )
    else
      not_found
    end
  end
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
end
