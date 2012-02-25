StarGtfs::Application.routes.draw do
  match "line/:id"                                            => redirect {|params,req| "/city/#{Agency.first.to_param}/line/#{params[:id]}" }
  match "line/:id/at/:stop_id"                                => redirect {|params,req| "/city/#{Agency.first.to_param}/line/#{params[:id]}/at/#{params[:stop_id]}" }
  match "stops"                                               => redirect {|params,req| "/city/#{Agency.first.to_param}/stops" }
  # probably wrong regarding the headsign
  match "schedule/:line_id/at/:stop_id(/toward/:headsign_id)" => redirect {|params,req| "/city/#{Agency.first.to_param}/schedule/#{params[:line_id]}/at/#{params[:stop_id]}" + ( params.has_key?(:headsign_id) ? "/toward/#{params[:headsign_id]})" : "" ) }
  match "schedule/legacy/:route_id/at/:stop_id"               => redirect {|params,req| "/city/#{Agency.first.to_param}/schedule/legacy/#{params[:route_id]}/at/#{params[:stop_id]}" }
  match "schedule/at/:stop_id/"                               => redirect {|params,req| "/city/#{Agency.first.to_param}/schedule/at/#{params[:stop_id]}" }
    
  match "city/:agency_id" => "home#show", :as => :agency
  match "city/:agency_id/line/:id" => "home#line", :as => :home_line
  match "city/:agency_id/line/:id/at/:stop_id" => "home#line"
  match "city/:agency_id/line/:id/at/:stop_id" => "home#line"
  match "city/:agency_id/stops" => "home#stops"
  match "city/:agency_id/schedule/:line_id/at/:stop_id(/toward/:headsign_id)" => "home#schedule"
  match "city/:agency_id/schedule/legacy/:route_id/at/:stop_id" => "home#schedule"
  match "city/:agency_id/schedule/at/:stop_id/" => "home#schedule"


  # match "line/:id" => "home#line", :as => :home_line
  # match "line/:id/at/:stop_id" => "home#line"
  # match "stops" => "home#stops"
  # match "schedule/:line_id/at/:stop_id(/toward/:headsign_id)" => "home#schedule"
  # match "schedule/legacy/:route_id/at/:stop_id" => "home#schedule"
  # match "schedule/at/:stop_id/" => "home#schedule"


  root :to => "home#redirect_root"

  if Rails.env.development?
    namespace :dump do
      resources :lines do
        resources :stops do
          resources :stop_times
        end
        resources :headsigns
        resources :polylines
        member do
          get :bearings
        end
      end
      resources :cities
      resources :stops do
        collection do
          get :main_ids
        end
        member do
          get :close
        end
	resources :stop_aliases
      end        
    end
  end

end
