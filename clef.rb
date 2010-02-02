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

class Clef < BarObject
  attr_accessor :style_id
  def initialize

  end

  def initialize_from_xml(xml)
    super(xml)
    @style_id = xml["StyleId"].split(".")[1]
  end

  def Clef.new_from_xml(xml)
    ts = Clef.new
    ts.initialize_from_xml(xml)
    ts
  end

  def to_ly
    return "\\clef " + @style_id + " "
  end
end