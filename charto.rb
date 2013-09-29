# File: charto.rb (jason CHarney's cARTOgraphy module)
# Date: 24 Sep 2013
# Author: Jason Charney, BSCS (jrcharneyATgmailDOTcom)
# Info: Contains the module Geo for calculating geographcial distances and directions.

# Module: Geo
# Info: Group to gether the functions used for great circle calculations
module Geo
 # Constants
 # Note: use Geo::R_EARTH outside of this module
 R_EARTH = 3958.91		# The mean radius of the Earth in miles. (Hey look! A CONSTANT!)
 
 # Methods
 # NOTE: Use Geo.to_coord(str) outside this module
 # Func: to_coord
 # Info: Convert a coordinate string into a floating point value
 # TODO: Only do the chop if str is a str not a float.
 # NOTE: This function is fine no matter what the debugger says.
 def self.to_coord(str)
  return (( str[-1] =~ /[SW]/ ) ? -1 : 1 ) * str.chop.to_f
 end

 # Func: to_degs
 # Info: convert radians to degrees
 def self.to_degs(rads)
  return rads * 180 / Math::PI
 end

 # Func: to_rads
 # Info: convert degrees to radians
 def self.to_rads(degs)
  return degs * Math::PI / 180
 end
 
 # Func: haversin
 # Info: half versed sine
 def self.haversin(angle)
  return (1-Math.cos(angle))/2
 end

 # Func: distance
 # Info: Calculate the spherical "as-the-crow-flies" distance between two points.
 # TODO: What if there was a way to output both distance and bearing calculations?
 #	The outputs would need to define their own getter functions rather than use the getter accessor.
 #	On the other hand, we would cut down on a lot of math.
 def self.distance(lat0,lon0,lat1,lon1)
  # TODO: if the last char is S or W, make the value negative
  @phi0 = to_rads(to_coord(lat0))
  @lam0 = to_rads(to_coord(lon0))		# actually lambda, but lambda is a reserved word.
  @phi1 = to_rads(to_coord(lat1))		# TODO: are @lat and lat two different variables?
  @lam1 = to_rads(to_coord(lon1))		# TODO: ditto
  @dlat = @phi1-@phi0
  @dlon = @lam1-@lam0
  @a = haversin(@dlat) + Math.cos(@phi0) * Math.cos(@phi1) * haversin(@dlon)
  @c = 2 * Math.atan2(Math.sqrt(@a),Math.sqrt(1-@a));
  @d = R_EARTH * @c
  return @d
 end

 # Func: bearing
 # Info: Calculate the bearing direction in degrees of point 1 relative to point 0
 # NOTE: I've had some issues with this function when it was written in bash/awk. I'm hoping to resolve them in Ruby.
 # TODO: Would it be wise to combine this method with the previous method?
 # TODO: For some reason, bearing still doesn't want to work correctly.
 def self.bearing(lat0,lon0,lat1,lon1)
  @phi0 = to_rads(to_coord(lat0))
  @lam0 = to_rads(to_coord(lon0))
  @phi1 = to_rads(to_coord(lat1))
  @lam1 = to_rads(to_coord(lon1))
  @dlat = @phi1-@phi0
  @dlon = @lam1-@lam0
  @dy = Math.sin(@dlon) * Math.cos(@phi1)
  @dx = Math.cos(@phi0) * Math.sin(@phi1) - Math.sin(@phi0) * Math.cos(@phi1) * Math.cos(@dlon)
  @th = to_degs(Math.sqrt(Math.atan2(@dy,@dx)**2))	# The absolute vaule of atan(y/x)

  #                                  +dy,-dx      +dy,+dx                 -dy,-dx      -dy,+dx
  @th = (@dy >= 0) ? (( @dx < 0 ) ? (180 - @th) : @th ) : (( @dx < 0 ) ? (180 + @th) : (360 - @th ))
  # @th = (@dlon >= 0) ? (( @dlat < 0 ) ? (180 - @th) : @th ) : (( @dlat < 0 ) ? (180 + @th) : (360 - @th ))
  return @th
 end

 # Func: direction
 # Info: Calculate the cardinal direction using angles in degrees.
 # NOTE: If this doesn't work right, it's Geo#bearing's fault.
 def self.direction(angle)
  # @angle = bearing(lat,lon)	# TODO: Maybe as a second form of this function.  Yeah, the second form can be public.
  @out = if( angle >= 348.75 || angle < 11.25 ) then "N"
         elsif( angle >= 11.25 && angle < 33.75 ) then "NNE"
         elsif( angle >= 33.75 && angle < 56.25 ) then "NE"
         elsif( angle >= 56.25 && angle < 78.75 ) then "ENE"
         elsif( angle >= 78.75 && angle < 101.25 ) then "E"
         elsif( angle >= 101.25 && angle < 123.75 ) then "ESE"
         elsif( angle >= 123.75 && angle < 146.25 ) then "SE"
         elsif( angle >= 146.25 && angle < 168.75 ) then "SSE"
         elsif( angle >= 168.75 && angle < 191.25 ) then "S"
         elsif( angle >= 191.25 && angle < 213.75 ) then "SSW"
         elsif( angle >= 213.75 && angle < 236.25 ) then "SW"
         elsif( angle >= 236.25 && angle < 258.75 ) then "WSW"
         elsif( angle >= 258.75 && angle < 281.25 ) then "W"
         elsif( angle >= 281.25 && angle < 303.75 ) then "WNW"
         elsif( angle >= 303.75 && angle < 326.25 ) then "NW"
         elsif( angle >= 326.25 && angle < 348.75 ) then "NNW"
	 end
  return @out
 end
end
