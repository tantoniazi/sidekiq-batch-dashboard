Sidekiq::Batch::Dashboard::Engine.routes.draw do
  root to: "batches#index"
  resources :batches, only: %i[index show], param: :id
  get "jobs", to: "jobs#index"
  get "failures", to: "failures#index"
  post "failures/:jid/retry", to: "failures#retry", as: :retry_failure
  get "progress", to: "progress#index"
end
