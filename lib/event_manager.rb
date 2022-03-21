# frozen_string_literal: true

# ruby event_manager.rb
require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  number_list = ('0'..'9').to_a
  cleaned_number = []
  phone.split('').each { |char| cleaned_number.push(char) if number_list.include?(char) }
  validate_number(cleaned_number)
end

def validate_number(phone)
  if phone.length == 10
    format(phone).join
  elsif phone.length == 11 && phone[0] == 1
    format(phone.slice(0)).join
  else
    'Invalid number'
  end
end

def format(phone)
  phone.insert(0, '(')
  phone.insert(4, ')')
  phone.insert(5, '-')
  phone.insert(9, '-')
end

def time_maker(time)
  DateTime.strptime(time, '%m/%d/%y %H:%M')
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  '../event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
hours = {}
weeks = {}

template_letter = File.read('../form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phone(row[:homephone])
  date = time_maker(row[:regdate])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  hours[date.hour] = 0 if hours[date.hour].nil?
  hours[date.hour] += 1

  week_days = %w[Sunday Monday Tuesday Wednsday Thursday Friday Saturday]
  weeks[week_days[date.wday]] = 0 if weeks[week_days[date.wday]].nil?
  weeks[week_days[date.wday]] += 1

  p "#{date.month}/#{date.day}/#{date.year} - #{week_days[date.wday]} - #{phone} - #{name}"
  # form_letter = erb_template.result(binding)
  # save_thank_you_letter(id, form_letter)
end

def max_value(hash)
  hash.max_by { |_k, v| v }
end

# p max_value(weeks)
# p max_value(hours)
