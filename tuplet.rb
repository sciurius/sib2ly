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

class Tuplet < BarObject
  attr_accessor :left, :right, :played_duration, :parent_tuplet, :notes
  def initialize
    @notes = []
  end

  def initialize_from_xml(xml)
    initialize
    super(xml)
    @left = xml["Left"].to_i;
    @right = xml["Right"].to_i;
    @played_duration = xml["PlayedDuration"].to_i;
  end

  def Tuplet.new_from_xml(xml)
    tp = Tuplet.new
    tp.initialize_from_xml(xml)
    tp
  end

  def to_ly
    return "\\times " + @right.to_s + "/" + @left.to_s+ "{"
  end
end