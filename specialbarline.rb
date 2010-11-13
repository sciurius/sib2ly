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

class SpecialBarline < BarObject
  attr_accessor :barline_type
  def initialize
  end

  def initialize_from_xml(xml)
    initialize
    super(xml)
    @barline_type = xml["BarlineType"]
  end

  def new
    super
  end

  def SpecialBarline.new_from_xml(xml)
    sb = SpecialBarline.new
    sb.initialize_from_xml(xml)
    sb
  end

  def priority
    if @barline_type == "StartRepeat"
      return 20
    end
    super
  end

  def to_ly
    bar = "\\bar \""
    case @barline_type
    when "Final"
      bar << "|."
    when "Double"
      bar << "||"
    when "Dotted"
      bar << "dashed" # Sibelius 'dotted' means 'dashed'
    when "StartRepeat"
      bar << "|:"
    when "EndRepeat"
      bar << ":|"
    when "DoubleRepeat"
      bar << ":|:"
    when "Invisible"
      bar << ""
    when "Ticks"
      bar << "'"
    when "Normal", "Short", "BetweenStaves"
      bar = ""
    else
      warning "Unknown bar line type: " + @barline_type
      bar << "|"
    end
    if bar != ""
      bar << "\" "
    end
    bar << " | "
    return bar
  end

  def to_s
    return "Barline at " + @bar.to_s + ", position " + @position.to_s + ", type " + @barline_type
  end
end