# frozen_string_literal: true

require 'dry/monads'
class ConverterController < ApplicationController
  # before_action :allow_params
  
  include Dry::Monads[:maybe, :result, :try, :do]

  def new 
  end

  def add_exam_info
    doc = yield get_file(params[:file])
    table = yield extract_table(doc)
    cookies[:discs] = extract_header(table)

    cookies[:students] = extract_students(table)
    @res = cookies[:students]
  end

  def choose_electives
    cookies[:discs] = update_discs
    @res = cookies[:discs]
  end

  def personal_teachers
    
  end

  private

  def allow_params
    params.permit(:file)
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
    header.map do |disc|
      res = disc
      if res[:value].include? '/'
        cookies[:electives] = true
        names = res[:value].split ' / '
        res = names.map.with_index { |name, i| { id: res[:id] + "_#{i}", value: name } }
      end
      res
    end.flatten
  end

  def extract_students(table)
    table.map do |row|
      { name: row.css("td div[class='student-fio'] span[title='']").text,
        marks: row.css("td[class*='disc_1']", "td[class*='disc_2']", "td[class*='disc_8']")
                  .map { |mark| { id: mark['class'][/disc_\S+/], mark: mark.text[/[а-яА-Я]+/] } } }
    end
  end

  def update_discs
    cookies[:discs].split('&').map! do |str|
      String.try_convert(str)
      # disc[:teacher] = params["#{disc[:id]}_teach".to_sym]
      # disc[:date] = params["#{disc[:id]}_date".to_sym]
      # disc[:hours] = params["#{disc[:id]}_hours".to_sym]
    end
  end
end
