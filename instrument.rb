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

class Instrument
  attr_accessor :staves
  def initialize(staves)
    if staves.is_a?(Array)
      @staves = staves
    else
      @staves = [staves]
    end
  end

  def family
    return @staves.first.family
  end
  def to_ly
    s = ""
    case staves.length
    when 1
      for staff in @staves
        case staff.num_stave_lines
        when 1
          s << "    \\new RhythmicStaff\n    {\n"
          s << "      \\set RhythmicStaff.instrumentName = \"" + staff.full_instrument_name + " \"\n"
          s << "      \\set RhythmicStaff.shortInstrumentName = \"" + staff.short_instrument_name + " \"\n"
          s << "      << \\global \\" + safe_instrument_name(staff.instrument_name) + " >>"
          s << "\n    }\n"
        when 5
          s << "    \\new Staff\n    {\n"
          s << "      \\set Staff.instrumentName = \"" + staff.full_instrument_name + " \"\n"
          s << "      \\set Staff.shortInstrumentName = \"" + staff.short_instrument_name + " \"\n"
          s << "      << \\global \\" + safe_instrument_name(staff.instrument_name) + " >>"
          s << "\n    }\n"
        end
      end
    when 2
      s << "    \\new PianoStaff\n"
      s << "    {\n"
      s << "      \\set PianoStaff.instrumentName = \"" + staves.first.full_instrument_name + " \"\n"
      s << "      \\set PianoStaff.shortInstrumentName = \"" + staves.first.short_instrument_name + " \"\n"
      s << "      <<\n"
      @staves.each_with_index do |staff, index|
        s << "        \\new Staff\n"
        if index > 0 # keep second staff from stretching vertically
          s << "        \\with\n"
          s << "        {\n"
          s << "          \\override VerticalAxisGroup #'keep-fixed-while-stretching = ##t\n"
          s << "        }\n"
        end
        s << "        {\n"
        s << "          << \\global \\" + safe_instrument_name(staff.instrument_name) + " >>"
        s << "\n        }\n"
      end
      s << "      >>\n"
      s << "    }\n"
    end
    return s
  end
end