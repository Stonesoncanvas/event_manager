require 'csv'
require 'sunlight'
require 'date'
 
class EventManager
 
INVALID_ZIPCODE = "00000"
INVALID_PHONENUMBER = "0000000000"
Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"
 
  def initialize(filename)
  	puts "EventManager Initialized"
		filename = "event_attendees.csv"
		@file = CSV.open(filename, 
			{headers: true, header_converters: :symbol})
	end
	def print_names
		@file.each do |line|
			#puts line.inspect
			#puts line[:first_name] + " " + line[:last_name]
		end
	end
	def clean_phonenumber(original)
	  		number = original.to_s.delete!("./ -/(/)")
  			if number.length == 10
  				number
			  elsif number.length == 11
  				if number.start_with?("1")
    				number = number[1..-1]
  				else
    				INVALID_PHONENUMBER
  				end
			  else
  			  INVALID_PHONENUMBER
			  end
		
	end
  	def print_numbers
    	@file.each do |line|
    	  	number = clean_phonenumber(line[:homephone])
      		puts number
    	end
  	end
 
	def clean_zipcodes(original)
	  		number = original
  			if number.to_s.length == 5
  				number
			  elsif number.to_s.length == 4
				  "0" + number.to_s
			  else
  			  INVALID_ZIPCODE
			  end
	end
  	def print_zipcodes
    	@file.each do |line|
    	  	number = clean_zipcodes(line[:zipcode])
      		puts number
    	end
  	end
 
	def output_data(filename)
    	output = CSV.open(filename, "w")
    	@file.each do |line|
        
        begin
    		  if @file.lineno == 2
        		output << line.headers
      		else
      			line[:homephone] = clean_phonenumber(line[:homephone])
            line[:zipcode] = clean_zipcodes(line[:zipcode])
      			output << line
      		end
        rescue Exception => e
        end
    	end
  	end
 
 	def rep_lookup
      20.times do
      	line = @file.readline
      	legislators = Sunlight::Legislator.all_in_zipcode(clean_zipcodes(line[:zipcode]))
			names = legislators.collect do |leg|
			  first_name = leg.firstname
			  first_initial = first_name[0]
			  last_name = leg.lastname
        party = leg.party
        title = leg.title
			  title + " " + first_initial + ". " + last_name + "(" + party + ")"
			end
    	representative = "unknown"
    	puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
      end
    end

  def create_form_letters
    letter = File.open("form_letter.html", "r").read
    20.times do
      line = @file.readline
      custom_letter = letter.gsub("#first_name","#{line[:first_name]}")
      custom_letter = custom_letter.gsub("#last_name","#{line[:last_name]}")
      custom_letter = custom_letter.gsub("#city","#{line[:city]}")
      custom_letter = custom_letter.gsub("#state","#{line[:state]}")
      custom_letter = custom_letter.gsub("#street","#{line[:street]}")
      custom_letter = custom_letter.gsub("#zipcode","#{line[:zipcode]}")
      filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
      output = File.new(filename, "w")
      output.write(custom_letter)
    end
  end

  def rank_times
    hours = Array.new(24){0}
    @file.each do |line|
      hour = line[:regdate][-5,2].to_i
      hours[hour] += 1
    end
    hours.each_with_index{|counter,hour| puts "#{hour}\t#{counter}"}
  end

  def day_stats
    weekdays = Array.new(7){0}
    @file.each do |line|
      weekday = line[:regdate][0,7]
      date = Date.strptime(weekday, "%m/%d/%y").wday
      weekdays[date] += 1
    end
    weekdays.each_with_index{|counter,date| puts "#{date}\t#{counter}"}
  end

  def state_stats
    state_data = {}
    @file.each do |line|
      state = line[:state]  # Find the State
        if state_data[state].nil? # Does the state's bucket exist in state_data?
          state_data[state] = 1 # If that bucket was nil then start it with this one person
        else
          state_data[state] = state_data[state] + 1  # If the bucket exists, add one
        end
    end
    ranks = state_data.sort_by{|state, counter| - counter}.collect{|state, counter| state}
    state_data = state_data.select{|state, counter| state}.sort_by{|state, counter| state  unless state.nil?}
    state_data.each do |state, counter|
      puts "#{state}:\t#{counter}\t(#{ranks.index(state) + 1 })"
    end
  end

end

manager = EventManager.new("event_attendees_clean.csv")
manager.state_stats
#puts manager.output_data("event_attendees_clean.csv")
#puts manager.rep_lookup