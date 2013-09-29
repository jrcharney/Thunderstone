#!/usr/bin/ruby
# File: thunderstone.rb (formerly getlsrlsx.rb)
# Info: Fetches Local Storm Report (LSR) products from the National Weather Service (NWS) Office in St. Louis (LSX)
# Author: Jason Charney, BSCS (jrcharneyATgmailDOTcom)
# Version: 2.3 alpha (Ruby Edition)
# Date: 28 Sep 2013
# Software License: MIT LICENSE, GPL 2 LICENSE
# Requires Software: ruby, wget, ncurses (for any tput commands)
# TODO: 
# [ ] Should I use cURL instead of wget?
# [ ] Use require instead of require_relative for compatiblity.
# NOTE: Sure I could have NOT used 'return' in a lot of these functions, but that would be wreckless programming IMHO.
# NOTE: This version is a cleaned up version of 2.1.
# NOTE: New name! I was thinking "GetStorm", but ThunderStone sounded way better.
# Changes:
#  Added a special case for when there are no reports available.
# TODO TODO TODO WARNING!: This program is not yet complete! I haven't tested with summaries which
#		are multiple postings, but in a single post.
#		We need a good severe storm to generate some new data before I can complete this program.
#		The bash version can do this, but this version can only do reports with single items in them.

# dims = { :height => %x{#{%Q{tput lines}}}.to_i, :width => %x{#{%Q{tput cols}}}.to_i }	# Terminal console dimensions 

# load 'chased.rb'
# require_relative 'chased'
# require_relative 'charto'
require './chased'
require './charto'


def wget(url)
 # @cmd="wget -q -O- '#{url}'"
 # %x{#{@cmd}}
 %x{#{%Q{wget -q -O- '#{url}'}}}
end


# Func: hr (horizontal rule)
# Info: Create a line full of dashes to separate records
# TODO: Use a number based on tput in the future. Just a thought.
def hr
 80.times { printf "-" }
 printf "\n"
end

# Class: WXReport
# NOTE: This class has nothing to do with WX or WXObjects.
# NOTE: The objects created in this class are intended for the creation of INDIVIDUAL reports, not summaries.
# NOTE: This class represents local storm report products, not forecasts, not observations and not advisories.
#	 Eventually, I'll make something that does that. For now, this is what I got.
# TODO: id each report (I think MIDX has that covered along with Ruby's built-in stuff.)
# TODO: Re organize methods. The Public and Private methods are getting messy.
# NOTE: Yes, I did use raw escapes on the colors escapes. Because its easier than using tput!
# TODO: Make 'getProductRange' a class method of this class
class WXReport
 @@reports = 0		# number of reports
 @@versions = 0		# Set to zero, but this should change quickly after the first report gets the proper value.
 @@color = true		# Enable colors
 @@empty = false	# Report if the queue is empty.
 def initialize(version=1,product="LSR",site="LSX",issuedby="LSX")
  @url="http://forecast.weather.gov/product.php?site=#{site}&issuedby=#{issuedby}&product=#{product}&format=txt&version=#{version}&glossary=0"
  # NOTE: Moved reports up toward the top so that if this is the first report, WXReport must find the version
  @raw=Chased.wgo(@url)		# Get the full page. This will be filtered out by the other functions

  if @raw =~ /None issued by this office recently\./
   printf "Sorry. No reports available.\n"
   @@empty = true
   return 0
  end

  # TODO: Should I add the FS RE / {2,}/ to this array?
  @re = {						# The regular expressions commonly used to describe stuff
   :vct   => '<pre class="glossaryProduct">',		# The number of reports note.  # TODO: I assume this is where it is every time.
   :detag => '<[^>]+>([^<]+)<\/[^>]+>',			# Used for stripping out the contents from a proper tag set.
   :midx  => "K#{site}",				# This should look up the line with the Message Index TODO: Test this!
   :first => '^000$',					# Every report starts with three zeros
   :time  => '^[0-9]{4} [AP]M {2,}',			# The first line of data with the time stamp
   :date  => '^[0-9]{2}/[0-9]{2}/[0-9]{4} {2,}',	# The second line of data with the date stamp
   :last  => '^&&$'					# Every report ends with two ampersands unless # TODO: or is it "^\$\$$"?
  }
  
  @@reports += 1	# NOTE: RUBY HAS NO INCREMENT OPERATORS! So @@reports++ does not work.
  if @@reports == 1
   @@versions=Chased.lp(@raw,@re[:vct]).gsub(/#{@re[:detag]}/,'\1').split[0].to_i	# Note: this only strips out the first instance that there is a tag set to strip out.
  end

  @page     = Chased.rp(@raw,@re[:first],@re[:last])		# We WANT to include the boundry lines so that we can output remarks
  @midx     = Chased.lp(@page,@re[:midx]).split[2]		# Contains midx
  @timeline = Chased.lp(@page,@re[:time]).strip.split(/ {2,}/)	# Contains time, event, city, latlon
  @dateline = Chased.lp(@page,@re[:date]).strip.split(/ {2,}/)	# Contains date, magintude (if any), county, and source (which we won't need)
  @dateline.insert(1,"N/A") if( @dateline.count == 4 )		# Insert "N/A" for the magnitude if there isn't one.
  @time, @event, @city, @lat, @lon = @timeline
  @date, @magnitude, @county, @state, @source = @dateline
  # TODO: Look ahead to see if the lines after the remarks contain the last line or the start of another report.
  @remarks = Chased.xrp(@page,@re[:date],@re[:last]).gsub(/\n +/," ").strip	# Contains the remarks lines after the dateline to the '^&&$' line or the time line of the next report 
 end

 # public
 # Func: distance
 # Info: Calculate the spherical "as-the-crow-flies" distance between two points.
 # Note: For lat and lon, I had it set for a business in Florissant that deals with roofing.
 def distance(lat="38.79N",lon="90.33W")
  return Geo.distance(lat,lon,@lat,@lon)
 end

 # Func: bearing
 # Info: Calculate the bearing degree of a set of coordiates.
 def bearing(lat="38.79N",lon="90.33W")
  return Geo.bearing(lat,lon,@lat,@lon)
 end
 
 # Func: direction
 # Info: Find the cardinal direction with the given bearing angle
 # NOTE: If the answers look wrong, blame Geo#bearing
 def direction(angle)
  return Geo.direction(angle)
 end

 # Func: self.colors=
 # Info: Setter function for the colors setting
 # CLASS METHOD!
 def self.colors=(color)
  @@color = color
 end

 # Func: self.colors
 # Info: Getter function for the colors setting
 # CLASS METHOD!
 def self.colors
  return @@color
 end

 # Func: self.colors?
 # Info: Determine if colors should be enabled.
 # H/T: To Patrick Joyce for fixing Ruby's "truthiness". Now if only someone can fix the "wikiality" of Ruby-Doc.org
 #  http://pragmati.st/2012/03/24/the-elements-of-ruby-style-predicate-methods/
 # PREDICATE METHOD AND CLASS METHOD!
 def self.colors?
  return !!@@color	# Returns true or false rather than false and nil.
 end

 def colors?
  return !!@@color
 end

 def self.empty?
  return !!@@empty
 end

 def empty?
  return !!@@empty
 end

 def self.reports
  return @@reports
 end

 def self.versions
  return @@versions
 end

 private
 # Func: ecf (event conditional formating)
 # Info: Display color events with colors!
 # Note: This function should be private
 # TODO: Maybe using a Hash for colors isn't the best plan. Rewrite with literals later.
 # TODO: Expand the color palette for winter precipitation
 # NOTE: Sure, Ruby converts \x1b into \e, but I'm more used to doing it with hexidecimal codes.
 # NOTE: Colors should ALWAYS be reset after you are done using them with '\x1b[0m'.
 #	If you don't use it, you're going to have a bad time, and your terminal will be stuck with
 #	that color until the reset sequence is executed.
 # TODO: Add more events. Flash Flooding is a common report.
 def ecf(evt)
  # NOTE: Just as a reminder, unless x is the same as if !x
  return evt unless self.colors? 	# This self.colors? is the colors? function not self.colors?
  @out = case evt 
   when /TORNADO|FUNNEL CLOUD/ then %Q{\x1b[1;37;41m#{evt}\x1b[0m}		# White with red background
   when /HAIL/ then %Q{\x1b[1;31m#{evt}\x1b[0m}					# Red
   when /TSTM WND DMG/ then %Q{\x1b[0;33m#{evt}\x1b[0m}				# Orange (or brown depending on POV)
   when /TSTM WND GST/ then %Q{\x1b[1;33m#{evt}\x1b[0m}				# Yellow
   when /HEAVY RAIN/ then %Q{\x1b[0;32m#{evt}\x1b[0m}				# Green (Note: 'Lime' is the brighter green)
   else evt
  end
  return @out
 end

 # Func: dcf (distance conditional formatting)
 # Info: Calculate the distance that this event is currently from the user.
 # Note: This may use some google maps magic. (UPDATE: Nope. I was thinking of something else.)
 # TODO: Include the Math module?
 # Note: Floating point ranges aren't simpatico with case-when blocks
 def dcf(dist)
  return dist if !self.colors?	# If self.colors? is false, don't use this function.
  @out = if(dist <= 25) then %Q{\x1b[0;32m#{dist}\x1b[0m}	# Green zone = 25 miles or less
   elsif (dist <= 50 ) then %Q{\x1b[1;33m#{dist}\x1b[0m}	# Yellow zone = 50 miles or less
   elsif (dist <= 75 ) then %Q{\x1b[0;33m#{dist}\x1b[0m}	# Orange zone = 75 miles or less
   else %Q{\x1b[1;31m#{dist}\x1b[0m}				# Red zone = Over 75 miles
   end
  return @out
 end
 
 # Func: self.headers
 # Info: When WXReports are displayed as a row (via WXReport#row), use this method to label the columns.
 # TODO: Find a way to create a common set of row variables for both this method and #row
 # CLASS METHOD! (Use WXReports.headers to use it.)
 def self.headers
  printf("\x1b[1;33m") if self.colors?			# Color this row yellow
  printf("%-8s","MIDX")			# Message Index
  printf("%-12s","DATE")		# Date of the reported incident
  printf("%-9s","TIME")		# Time of the reported incident
  printf("%-17s","EVENT")		# Type of weathe event
  printf("%-17s","MAGNITUDE")		# Magnitude of the event (if available)
  printf("%-23s","CITY")		# City or location where the event took place
  printf("%-23s","COUNTY")		# County the city or location is in
  printf("%-4s","ST")			# State the city or location is in
  printf("%-9s%-9s","LAT","LON")	# The geographic coordinates of the city or location
  printf("%-11s","DIST")			# The distance to the location from HOME in miles. (This could be adjusted for other locations.)
  printf("%-9s","BER")			# Bearing direction of the location (in degrees)
  printf("%-6s","DIR")			# Cardinal direction of the location (as a direction)
  # printf("%-9s","ZIP")		# The zipcode of the location (TODO: Find a database that I can pull up that info.)
  printf("%-16s ","SOURCE")
  printf("%-16s","REMARKS")
  printf("\x1b[0m") if self.colors?
  printf("\n")
 end

 public
 # Func: row
 # Info: Display report information as a row
 # TODO: Set field widths instead of using tabs. (We should still make widths long enouth to use / {2,}/ as FS.
 # TODO: Should I combine @date and @time to form @datetime? (no.)
 # TODO: Distance and bering calculators
 # TODO: Conditionally formatted magnitude.
 def row
  # Breaking it down vertically helps
  # TODO: Message Index field: Find the message index in the reports.
  printf("%-8s",@midx)
  printf("%-12s%-9s",@date,@time)
  printf("%-28s",ecf(@event))
  printf("%-17s",@magnitude)		# Magnitudes could be "N/A", in MPH for winds, or Inches for precipitation
  printf("%-23s",@city)
  printf("%-23s",@county)
  printf("%-5s",@state)
  printf("%-9s%-9s",@lat,@lon) 
  printf("%-21s",dcf(distance.round(2)))	# dcf returns a string
  printf("%6.2f",bearing.round(2))
  printf("%6s",direction(bearing))
  # printf("%-9s","ZIP")    
  printf("%18s  ",@source)
  printf("%s\n",@remarks)
 end
 # Most of these vaules can't really be changed, so we only need to define the getters.
 # These can be public.  Basically :time is the getter for @time.
 attr_reader :page	# raw page
 attr_reader :midx	# Message index.	This number will be useful for identifing summaries and duplicates
 attr_reader :timeline	# raw timeline
 attr_reader :dateline	# raw dateline
 attr_reader :time	# hhmm [A|P]M
 attr_reader :event	# Type of weather event
 attr_reader :magnitude	# This can be empty
 attr_reader :city	# This may contain a distance leading
 attr_reader :lat	# Latitude
 attr_reader :lon	# Longitude
 attr_reader :date	# MM/DD/YYYY
 attr_reader :county	# This field shouldn't.
 attr_reader :state	# short two letter (i.e. MO or IL)
 attr_reader :source	# The source of the report (We won't really use this field a whole lot. It exists so that everything works.)
 attr_reader :remarks	# This can be empty
 #attr_reader :distance
 #attr_reader :bearing
 #attr_reader :direction
 #attr_reader :zip
 # attr_accessor :color		# TODO: Can this be a class variable?
end

reports = Array.new
reports[0] = WXReport.new(1)

unless WXReport.empty?
 (1..WXReport.versions).each { |v| reports.push(WXReport.new(v)) unless v == 1 }
 WXReport.headers	# NOTE: Class methods will not execute unless there is at leas on instance of that class in existance.
 reports.each { |v| v.row }
end

# TODO: If this works, write the results to a file!
# TODO: If you are going to write to a file, disabled the colors so the escapes aren't written.
