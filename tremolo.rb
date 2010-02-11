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

class Tremolo < BarObject
  attr_accessor :note_rests
  def initialize(nr)
      @note_rests = [*nr]
  end

  def to_ly
    s = ""
    @note_rests.each do |nr|
      td = get_tremolo_duration(nr.duration, nr.single_tremolos)
      s << "\\repeat tremolo #{(nr.duration / td).to_s} "
      nr.duration = td
      s << nr.to_ly
      #  s << '^\markup {' << @note_rests.first.single_tremolos.to_s << '}'
    end
    return s
  end
end