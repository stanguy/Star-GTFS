StarGtfs::Application.routes.draw do
  match "line/:id" => "home#line", :as => :home_line
  match "line/:id/at/:stop_id" => "home#line"
  match "stops" => "home#stops"
  match "schedule/:line_id/at/:stop_id(/toward/:headsign_id)" => "home#schedule"
  match "schedule/legacy/:route_id/at/:stop_id" => "home#schedule"
  match "schedule/at/:stop_id/" => "home#schedule"

  root :to => "home#show"

  if Rails.env.development?
    namespace :dump do
      resources :lines do
        resources :stops
      end
      resources :cities
    end
  end

end
