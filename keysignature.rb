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

class KeySignature < BarObject
  attr_accessor :as_text, :major
  def initialize

  end

  def priority
    10
  end

  def initialize_from_xml(xml)
    super(xml)
    @as_text = xml["AsText"].downcase;
    @major = xml["Major"].eql?("true");
  end

  def KeySignature.new_from_xml(xml)
    ks = KeySignature.new
    ks.initialize_from_xml(xml)
    ks
  end

  def to_ly
    if @as_text == "atonal"
      s = "\\key c "
    else
      s = "\\key " + written_name2ly(@as_text) + " "
    end
    if @major
      s << "\\major "
    else
      s << "\\minor "
    end
    return s
  end
end