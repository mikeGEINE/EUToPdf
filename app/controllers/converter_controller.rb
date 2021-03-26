# frozen_string_literal: true

require 'dry/monads'
class ConverterController < ApplicationController
  # before_action :allow_params
  
  include Dry::Monads[:maybe, :result, :try, :do]

  def new 
  end

  def convert
    doc = yield get_file(params[:file])
    table = yield extract_table(doc)
    cookies[:header] = extract_header(table)

    cookies[:students] = extract_students(table)
    @res = cookies[:students]
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
        names = res[:value].split ' / '
        res = names.map { |name| { id: res[:id], value: name } }
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
end
