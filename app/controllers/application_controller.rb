class ApplicationController < ActionController::Base
  protect_from_forgery

  private
  def render_404()
    render :file => "error_pages/404.html", :layout => false, :status => :not_found
  end
      

end
