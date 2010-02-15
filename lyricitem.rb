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
require 'duration'

class LyricItem < BarObject
	attr_accessor :text, :style_id,
  :duration, :num_notes, :syllable_type
	def initialize

	end

	def initialize_from_xml(xml)
		super(xml)

		# Get the visible part of text only
		@text = unescape_xml(xml["Text"]).split("~").first

		# Make sure @text is not nil
		@text = "" unless @text
		@style_id = xml["StyleId"]
		@syllable_type = xml["SyllableType"].to_i
		@num_notes = xml["NumNotes"].to_i
    @duration = Duration.new(xml["Duration"].to_i)
	end

	def LyricItem.new_from_xml(xml)
		li = LyricItem.new
		li.initialize_from_xml(xml)
		li
	end

  #	def to_ly
  #		s = ""
  #		return "" if (!@text or @hidden or @text.empty?)
  #		case @syllable_type
  #		when 0 # Middle of word
  #			s << @text.gsub(' ', '_')
  #			s << " -- "
  #			(@num_notes - 1).times {s << " __ "}
  #		when 1 # End of word
  #			s << @text.gsub(' ', '_')
  #			s << " "
  #			(@num_notes - 1).times {s << " __ "}
  #		else
  #			warning "Unknown syllable type."
  #		end
  #		s
  #	end

  def to_ly
    s = ""
    if @hidden
      s << "\\skip "
      s << @duration.to_ly << " "
    else
      s << @text.gsub(' ', '_')
      s << @duration.to_ly << " "
    end
    
    unless @hidden
      case @syllable_type
      when 0 # Middle of word
        s << " -- "
        #(@num_notes - 1).times {s << " _ "}
      when 1 # End of word
        if @num_notes == 1
          s << " "
        else
          s << " __ "
        end
        #(@num_notes - 1).times {s << " __ "}
      else
        warning "Unknown syllable type."
      end
    end
    s
  end
end
