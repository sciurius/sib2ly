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

class StaffGroup
  attr_accessor :instruments, :bracket
  def initialize
    @instruments = []
    @bracket = true
  end

  def <<(instrument)
    @instruments += instrument
  end

  def to_ly
    s = ""
    if @instruments.empty?
      return s
    end
    if @bracket
      s << "  \\new StaffGroup\n"
      s << "  {\n"
      s << "    <<\n"
    end
    for instrument in @instruments
      s << instrument.to_ly
    end
    if @bracket
      s << "\n    >>\n  } % StaffGroup\n"
    end
    return s
  end
end