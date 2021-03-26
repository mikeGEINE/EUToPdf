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
    header = table.shift.css("th[class^='disc_1']", "th[class^='disc_2']", "th[class^='disc_8']").map do |cell|
      { id: cell['class'].split(' ').first, value: cell.text.split("\n").second }
    end
    @res = header
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
    Maybe(doc.css('table.eu-table'))
      .to_result
      .or Failure(:no_table)
  end

  def open_file(file)
    Nokogiri::HTML(file.open)
  end
end
