# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'converter#new'

  get 'converter/new'
  match 'converter/convert', to: 'converter#convert', via: %i[get post]
  match 'converter/add_exam_info', to: 'converter#add_exam_info', via: %i[get post]
  match 'converter/personal_teachers', to: 'converter#personal_teachers', via: %i[get post]
  match 'converter/choose_electives', to: 'converter#choose_electives', via: %i[get post]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
