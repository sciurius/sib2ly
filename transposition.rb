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

require 'barobject'

class TranspositionBegin < BarObject
	attr_reader :transposition

	def initialize(transposition)
		@transposition = transposition
	end

  # Comes before NoteRest and KeySignature
  def priority
    20
  end

	def to_ly
		s = ""
		s << "\\transpose #{compute_transposition(@transposition)} c {"
		s
	end

  private
  def compute_transposition(t)
    s = ""
		octave, cl = t.divmod(12)
		s << TRANSPOSITION[cl]
    #p octave
		octave.times {s << "'"}
		(-octave).times {s << ","}
		s
	end
end

class TranspositionEnd < BarObject
	def to_ly
		"}"
	end
end
