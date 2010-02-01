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
  def initialize

  end

  def initialize_from_xml(xml)
    super(xml)
  end

  def SystemTextItem.new_from_xml(xml)
    t = SystemTextItem.new
    t.initialize_from_xml(xml)
    t
  end

  TEMPO_NOTE = {
    "W" => "\breve",
    "w" => "1",
    "h" => "2",
    "q" => "4",
    "e" => "8",
    "x" => "16",
    "y" => "32"
  }

  def tempo_note_to_dur(note, dots)
#    x = TEMPO_NOTE[note]
#    unless x
#      puts note
#    end
    return TEMPO_NOTE[note] + dots
  end

  def to_ly
    s = ""
    case @style_id
    when "text.system.tempo", "text.system.metronome"

      match = /\s*((|(\S*\s*)*\S))\s*\(([Wwhqexy])(\.*)\s*=\s*(\d+)\)\s*/.match(@text)
      if match
        tempo_text = match[1]
        note = match[4]
        dots = match[5]
        number = match[6]
        s << "\\tempo \"" << tempo_text << "\" " << tempo_note_to_dur(note, dots) << " = " << number << " "
      else
        match = /\s*((|(\S*\s*)*\S))\s*\(([Wwhqexy])(\.*)\s*=\s*(\d+)\)\s*/.match(@text)
        if match
          tempo_text = match[1]
          note = match[3]
          dots = match[4]
          number = match[5]
          s << "\\tempo \"" << tempo_text << "\" " << tempo_note_to_dur(note, dots) << " = " << number << " "
        else
          match = /\s*([Wwhqexy])(\.*)\s*=\s*(\d+)/.match(@text)
          if match
            note = match[1]
            dots = match[2]
            number = match[3]
            s << "\\tempo " << tempo_note_to_dur(note, dots) << " = " << number << " "
          else
            s << "\\tempo \"" << @text << "\" "
          end
        end
      end



      #        case @text
      #        when /\s*((|(\S*\s*)*\S))\s*\(([Wwhqexy])(\.*)\s*=\s*(\d+)\)\s*/
      #          tempo_text = $1
      #          note = $4
      #          dots = $5
      #          number = $6
      #          s << "\\tempo \"" << tempo_text << "\" " << tempo_note_to_dur(note, dots) << " = " << number << " "
      #        when /\s*((\S*\s*)*\S)\s*([Wwhqexy])(\.*)\s*=\s*(\d+)\s*/
      #          tempo_text = $1
      #          note = $3
      #          dots = $4
      #          number = $5
      #          s << "\\tempo \"" << tempo_text << "\" " << tempo_note_to_dur(note, dots) << " = " << number << " "
      #        when /\s*([Wwhqexy])(\.*)\s*=\s*(\d+)/
      #          note = $1
      #          dots = $2
      #          number = $3
      #          s << "\\tempo " << tempo_note_to_dur(note, dots) << " = " << number << " "
      #        else
      #          s << "\\tempo \"" << @text << "\" "
      #        end
    end
    return s
  end
end
