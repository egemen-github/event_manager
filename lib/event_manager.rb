# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_number(number)
    num = number.gsub(/([-() ])/, '')
    if num.length == 10
      num
    elsif num.length == 11 && num[0] == "1"
      num[1..-1]
    end
end

REGHOURS = []
def reg_hour(regdate)
  t = DateTime.strptime(regdate, "%m/%d/%Y %k:%M")
  REGHOURS << t.hour
end

REGDAYS = []
def reg_day(regdate)
  weekdays = DateTime::DAYNAMES
  t = DateTime.strptime(regdate, "%m/%d/%Y %k:%M")
  REGDAYS << weekdays[t.wday]
end

puts 'EventManager initialized.'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter



contents.each do |row|
  id = row[0]
  name = row[:first_name]
  number = row[:homephone]
  regdate = row[:regdate]
  
  reg_day(regdate)
  reg_hour(regdate)

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  number = clean_number(number)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts REGDAYS.tally.map { |day,num| "#{num} people registered on #{day}" }
puts REGHOURS.tally.map { |hour,num| "#{num} people registered at #{hour}" }