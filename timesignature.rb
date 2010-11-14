# This file is part of SIB2LY    Copyright 2010 Kirill Sidorov
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class TimeSignature < BarObject
  attr_accessor :numerator, :denominator
  def initialize(numerator = 4, denominator = 4)
    @numerator, @denominator = numerator, denominator
  end

  def priority
    12
  end

  def initialize_from_xml(xml)
    super(xml)
    @numerator = xml["Numerator"].to_i;
    @denominator = xml["Denominator"].to_i;
  end

  def TimeSignature.new_from_xml(xml)
    ts = TimeSignature.new
    ts.initialize_from_xml(xml)
    ts
  end

  # Return the duration of a Bar with such TimeSignature in Sibelius units
  def duration
    1024 * @numerator / @denominator;
  end

  def to_ly
    return "\\time " + @numerator.to_s + "/" + @denominator.to_s + " "
  end
end