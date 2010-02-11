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

require 'translatable'

class BarObject < Translatable
  attr_accessor  :position, :voice, :hidden, :dx, :dy, :bar
  def initialize
    @position, @voice, @hidden, @dx, @dy, @bar = 0, 1, false, 0, 0, nil
  end

  def priority
    0
  end

  def initialize_from_xml(xml)
    @position   = xml["position"].to_i;
    @voice      = xml["voicenumber"].to_i;
    @hidden     = xml["hidden"].eql?("true");
    @dx         = xml["dx"].to_i;
    @dy         = xml["dy"].to_i;
  end
end
