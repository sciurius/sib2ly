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

require 'constants'
require 'barobject'

class Text < BarObject
	attr_accessor :text, :style_id
	def initialize(text = nil, style_id = nil)
		super()
		@text, @style_id = text, style_id
	end

	def initialize_from_xml(xml)
		super(xml)

		# Get the visible part of text only
		@text = unescape_xml(xml["Text"]).split("~").first

		# Make sure @text is not nil
		@text = "" unless @text
    @text.strip!
		@style_id = xml["StyleId"]
	end

	def Text.new_from_xml(xml)
		t = Text.new
		t.initialize_from_xml(xml)
		t
	end

  def empty?
    to_ly.empty?
  end

  def dynamic?
    style_id == "text.staff.expression"
  end

	def to_ly
		s = ""
		return "" if !@text or @hidden or @text.empty?
		case @style_id
		when "text.staff.expression"
			exp = EXPRESSION[@text.downcase]
			if exp
				s << (dy < 0 ? "" : "^")
				s << exp
			else
				# warning "I do not know how to typeset the expression \"#{@text}\". Ignoring!"
				s << (dy < 0 ? "_" : "^")
				# Typeset the text as a \markup
				s << "\\markup \{\"" + @text + "\"\}"
			end
			#s << exp if exp
		when "text.staff.technique"
			# Try to guess if the text should be typeset above or below the staff
			s << (dy < 0 ? "_" : "^")
			# Typeset the text as a \markup
			s << "\\markup \{\\italic \{\"" + @text + "\"\}\}"
		when "text.staff.space.chordsymbol"
			# Chord symbols are now typeset correctly in \chordmode, see chord.rb
			#s << "^\\markup \{\"" + @text + "\"\}"
		end
		s
	end
end
