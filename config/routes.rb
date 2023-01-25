StarGtfs::Application.routes.draw do
  get "line/:id"                                            => redirect {|params,req| "/city/#{Agency.first.to_param}/line/#{params[:id]}" }
  get "line/:id/at/:stop_id"                                => redirect {|params,req| "/city/#{Agency.first.to_param}/line/#{params[:id]}/at/#{params[:stop_id]}" }
  get "stops"                                               => redirect {|params,req| "/city/#{Agency.first.to_param}/stops" }
  # probably wrong regarding the headsign
  get "schedule/:line_id/at/:stop_id(/toward/:headsign_id)" => redirect {|params,req| "/city/#{Agency.first.to_param}/schedule/#{params[:line_id]}/at/#{params[:stop_id]}" + ( params.has_key?(:headsign_id) ? "/toward/#{params[:headsign_id]})" : "" ) }
  get "schedule/legacy/:route_id/at/:stop_id"               => redirect {|params,req| "/city/#{Agency.first.to_param}/schedule/legacy/#{params[:route_id]}/at/#{params[:stop_id]}" }
  get "schedule/at/:stop_id/"                               => redirect {|params,req| "/city/#{Agency.first.to_param}/schedule/at/#{params[:stop_id]}" }

  get "city/:agency_id/offline" => "home#offline", :as => :offline
  get "city/:agency_id" => "home#show", :as => :agency
  get "city/:agency_id/line/:id" => "home#line", :as => :home_line
  get "city/:agency_id/line/:id/incidents" => "home#line_incidents", :as => :line
  get "city/:agency_id/line/:id/at/:stop_id" => "home#line", :as => :home_line_stop
  get "city/:agency_id/stops" => "home#stops"
  get "city/:agency_id/schedule/:line_id/at/:stop_id(/toward/:headsign_id)" => "home#schedule", :as => :line_stop_schedule
  get "city/:agency_id/schedule/legacy/:route_id/at/:stop_id" => "home#schedule"
  get "city/:agency_id/schedule/at/:stop_id/" => "home#schedule", :as => :stop_schedule
  get "city/:agency_id/search" => "home#search", :as => :search
  get "city/:agency_id/opensearch" => "home#opensearch", :as => :opensearch

  # get "line/:id" => "home#line", :as => :home_line
  # get "line/:id/at/:stop_id" => "home#line"
  # get "stops" => "home#stops"
  # get "schedule/:line_id/at/:stop_id(/toward/:headsign_id)" => "home#schedule"
  # get "schedule/legacy/:route_id/at/:stop_id" => "home#schedule"
  # get "schedule/at/:stop_id/" => "home#schedule"


  root :to => "home#redirect_root"

  if Rails.env.development?
    namespace :dump do
      resources :agencies do
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
        resources :calendars
        resources :calendar_dates
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

end
