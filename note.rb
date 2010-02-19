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

class Note
  attr_reader :pitch,  :written_pitch, :name, :written_name,
    :previous_note, :ottavation, :bracketed, :accidental,
    :written_accidental
	attr_accessor :diatonic_pitch, :written_diatonic_pitch, :tied
  def initialize(xml)
    @pitch = xml["Pitch"].to_i;
    @accidental = xml["Accidental"].to_i;
    @written_accidental = xml["WrittenAccidental"].to_i;
    @diatonic_pitch = xml["DiatonicPitch"].to_i;
    @written_pitch = xml["WrittenPitch"].to_i;
    @written_name = xml["WrittenName"];
    @name = xml["Name"];
    @tied = xml["Tied"].eql?("true");
    @bracketed = xml["Bracketed"].eql?("true");
    @written_diatonic_pitch = pitch2diatonic(@written_pitch, @written_name)
  end

	def transposition
		@pitch - @written_pitch
	end

	def previous_note=(note)
		assert((nil == note) || note.is_a?(Note), "Trying to assign a non-Note object to previous_note")
		@previous_note = note
	end

  def to_ly
    s = ""
    if @bracketed
      s << "\\parenthesize "
    end
    s << written_name2ly(@name)
    if @previous_note
      s << get_octave(@previous_note.diatonic_pitch, @diatonic_pitch)
    end
    if @tied
      s << "~ "
    end
    return s
  end

  alias to_s to_ly
end
