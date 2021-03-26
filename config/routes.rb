# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'converter#new'

  get 'converter/new'
  post 'converter/convert'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
