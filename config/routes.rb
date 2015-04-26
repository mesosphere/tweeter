Rails.application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'oinks#index'

  resources :oinks, except: %w(edit new update)

  resources :analytics, except: %w(create edit new update show)
end
