# frozen_string_literal: true

require 'dry/monads'
class ConverterController < ApplicationController
  before_action :class_params
  
  include Dry::Monads[:maybe, :result, :try, :do]

  def new 
  end

  def add_exam_info
    if request.post?
      doc = yield get_file(params[:file])
      table = yield extract_table(doc)
      @discs = extract_header(table)
      @students = extract_students(table)
    else
      flash[:alert] = 'You should upload a correct page from EU first!'
    end
  end

  def choose_electives
    if request.post?
      update_discs
      if @electives.blank?
        redirect_to(action: 'personal_teachers', notice: 'No electives detected, skipping...')
      end
    else
      flash[:alert] = 'You should upload a correct page from EU first!'
    end
  end

  def personal_teachers
    if request.post?
      elective_choices
      @res = (0...@electives.count).map { |i| params["#{i}_#{@students.first[:uuid]}".to_sym] }
      @personals = find_personals
      if @personals.blank?
        redirect_to(action: 'convert', notice: 'No disciplines with personal teachers found, skipping...')
      end
    else
      flash[:alert] = 'You should upload a correct page from EU first!'
    end
  end

  def convert
    if request.post?
      bind_personals
    else
      flash[:alert] = 'You should upload a correct page from EU first!'
    end
  end

  private

  def class_params
    @discs = JSON.parse(params[:discs], { symbolize_names: true }) if params[:discs].present?
    @students = JSON.parse(params[:students], { symbolize_names: true }) if params[:students].present?
    @electives = @discs.select { |disc| disc[:group].present? }.group_by { |disc| disc[:group] } if @discs.present?
  end

  def get_file(file)
    Maybe(open_file(file))
      .to_result
      .or Failure(:no_file)
  end

  def extract_table(doc)
    Maybe(doc.css('table.eu-table').css('tr'))
      .to_result
      .or Failure(:no_table)
  end

  def open_file(file)
    Nokogiri::HTML(file.open)
  end

  def extract_header(table)
    header = table.shift.css("th[class*='disc_1']", "th[class*='disc_2']", "th[class*='disc_8']").map do |cell|
      { id: cell['class'].split(' ').first, value: cell.text.split("\n").second }
    end
    find_electives(header)
  end

  def find_electives(header)
    group = 0
    header.map do |disc|
      res = disc
      if res[:value].include? '/'
        names = res[:value].split ' / '
        res = names.map.with_index { |name, i| { id: res[:id] + "_#{i}", value: name, group: group } }
        group.next
      end
      res
    end.flatten
  end

  def extract_students(table)
    table.map do |row|
      { uuid: row['student-uuid'],
        name: row.css("td div[class='student-fio'] span[title='']").text,
        marks: row.css("td[class*='disc_1']", "td[class*='disc_2']", "td[class*='disc_8']")
                  .map { |mark| { id: mark['class'][/disc_\S+/], mark: mark.text[/[а-яА-Я]+/] } } }
    end
  end

  def update_discs
    @discs.each do |disc|
      disc[:teacher] = params["#{disc[:id]}_teach".to_sym]
      disc[:date] = params["#{disc[:id]}_date".to_sym]
      disc[:hours] = params["#{disc[:id]}_hours".to_sym]
    end
  end

  def elective_choices
    @students.each do |student|
      selections = (0...@electives.count).map { |i| params["#{i}_#{student[:uuid]}".to_sym] }
      student[:marks].each do |disc|
        selections.each { |sel| Maybe(sel).bind { |s| disc[:id] = s if s.include?(disc[:id]) } }
      end
    end
  end

  def find_personals
    @discs.select do |disc|
      disc[:teacher].empty? || disc[:teacher].nil?
    end
  end

  def bind_personals
    @students.each do |student|
      selections = find_personals.map { |disc| { id: disc[:id], teacher: params["#{disc[:id]}_#{student[:uuid]}"]} }
      student[:marks].each do |disc|
        selections.each do |sel| 
          Maybe(sel).bind { |s| disc[:teacher] = s[:teacher] if s[:id].eql? disc[:id] } 
        end
      end
    end
  end
end
