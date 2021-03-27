# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'converter#new'

  get 'converter/new'
  post 'converter/convert'
  post 'converter/add_exam_info'
  post 'converter/choose_electives'
  post 'converter/personal_teachers'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
