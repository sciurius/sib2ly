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

class RelativeBegin < BarObject
	attr_reader :first_note
	def initialize(first_note)
		super()
		@first_note = first_note
	end

	# Comes before NoteRest but after TranspositionBegin
	def priority
		15
	end

	def to_ly
		return "\\relative c" + get_octave(35 - 7, @first_note.diatonic_pitch) + "{ ";
	end
end

class RelativeEnd < BarObject
	def initialize
		super
	end

	def to_ly
		"}"
	end
end

