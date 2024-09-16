# frozen_string_literal: true

# config/routes.rb
Rails.application.routes.draw do
  get 'auth/google_oauth2', to: 'sessions#new'
  get 'oauth2callback', to: 'sessions#create'
  get 'sync_google_calendar_events', to: 'events#sync_google_calendar_events'
  resources :events
  root 'events#index'
end
