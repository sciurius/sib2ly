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

class BarlineTweak < BarObject
  attr_accessor :tweak_type
  def initialize
    @tweak_type = ""
  end

  def priority
    return 127 #must be before noterests
  end

  def new
    super
  end

  def to_ly
    s = ""
    case @tweak_type
    when "Short"
      s << "\\override Staff.BarLine #'bar-size = #2\n\\override Staff.BarLine #'allow-span-bar = ##f"
    when "ShortEnd"
      s << "\\revert Staff.BarLine #'bar-size\n\\revert Staff.BarLine #'allow-span-bar"
    when "BetweenStaves"
      s << "\\override Staff.BarLine #'transparent = ##t\n\\override Staff.BarLine #'allow-span-bar = ##t"
    when "BetweenStavesEnd"
      s << "\\revert Staff.BarLine #'transparent\n\\revert Staff.BarLine #'allow-span-bar"
    else
      warning "Unknown bar line tweak type: " + @tweak_type
      s << ""
    end
    return "\n"+s+"\n"
  end

  def to_s
    return "BarlineTweak at " + @bar.to_s + ", position " + @position.to_s + ", type " + @tweak_type
  end
end