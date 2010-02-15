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

require 'text'
class SystemTextItem < Text

  def initialize_from_xml(xml)
    super(xml)
  end

  def SystemTextItem.new_from_xml(xml)
    t = SystemTextItem.new
    t.initialize_from_xml(xml)
    t
  end



  def tempo_note_to_dur(note, dots)
    #    x = TEMPO_NOTE[note]
    #    unless x
    #      puts note
    #    end
    return TEMPO_NOTE[note] + dots
  end

  def to_ly
    s = ""
    ts = @text.strip
    unless ts.empty?
      case @style_id
      when "text.system.tempo", "text.system.metronome"
        #match = /^((|(\S*\s*)*\S))\s*\(([Wwhqexy])(\.*)\s*=\s*(\d+)\)$/.match(@text.strip)
        match = /^(.*?)\(?\s*([Wwhqexy])(\.*)\s*=([^\d])*(\d+)\s*\)?$/.match(ts)
        if match
          tempo_text = match[1] ? match[1].strip : ""
          note =  match[2] ? match[2].strip : ""
          dots =  match[3] ? match[3].strip : ""
          qualifier =  match[4] ? match[4].strip : "" # as in: circa 120
          number =  match[5] ? match[5].strip : ""
          unless tempo_text.empty?
            s << "\\tempo \"" << tempo_text << "\" " << tempo_note_to_dur(note, dots) << " = " << number << " "
          else
            s << "\\tempo " << tempo_note_to_dur(note, dots) << " = " << number << " "
          end
        else
          match = /^([Wwhqexy])(\.*)\s*=\s*(\d+)$/.match(ts)
          if match
            note = match[1]
            dots = match[2]
            number = match[3]
            s << "\\tempo " << tempo_note_to_dur(note, dots) << " = " << number << " "
          else
            s << "\\tempo \"" << ts << "\" "
          end
        end
      end
    end
    return s
  end
end
