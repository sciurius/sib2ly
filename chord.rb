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

class Chord < BarObject
  attr_accessor :prefix, :postfix, :duration

  def initialize(prefix, postfix, position, duration)
    @prefix, @postfix, @position, @duration = prefix, postfix, position, duration
  end

  def to_ly
    s = @prefix
    f = @duration.gcd(1024);
    s << "1"
    s << "*"
    s << (@duration/f).to_s + "/" + (1024/f).to_s;
    s << ":" unless @postfix.empty?
    s << @postfix
    s << " "
    s
  end
end

def translate_chord_to_ly(sib)
  match = /^([A-H])(b|#|)(aug|maj|dim|sus2|sys4|sus|ma|mi|m|-|)(\^|[2-7]|9|11|13|)(\/[A-H](b|#|))?$/.match(sib)
  if match
    note       = match[1]
    accidental = match[2]
    type       = match[3]
    mod        = match[4]
    denom      = match[5]

    case type
    when "-"
      type = "m"
    end

    case mod
    when "^"
      mod = "maj"
    end

    if denom
    denom = "/" + written_name2ly(denom[1..-1])
    else
      denom = ""
    end
    [written_name2ly(note + accidental), type + mod + denom]
  else
    puts "WARNING: Unrecognised chord syntax: " + sib + ". Ignoring chord."
    ["s", ""]
  end
end