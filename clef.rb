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


# Mapping between Sibelius clef styles and their LilyPond counterparts.
CLEFS = {
	'clef.treble' 				=> 'treble',
	'clef.bass' 					=> 'bass',
	'clef.treble.down.8'	=> '"treble_8"',
	'clef.treble.up.8'		=> '"treble^8"',
	'clef.treble.up.15'		=> '"treble^15"',
	'clef.soprano' 				=> 'soprano',
	'clef.soprano.mezzo'	=> 'mezzosoprano',
	'clef.tab' 						=> 'tab',
	'clef.bass.up.15' 		=> '"bass^15"',
	'clef.bass.up.8' 			=> '"bass^8"',
	'clef.violin.french' 	=> 'french',
	'clef.baritone.c' 		=> 'baritone',
	'clef.baritone.f' 		=> 'varbaritone',
	'clef.alto' 					=> 'alto',
	'clef.tenor' 					=> 'tenor',
	'clef.percussion' 		=> 'percussion',
	'clef.null'						=> ''
}

class Clef < BarObject
  attr_reader :style_id
  def initialize(style_id = nil)
		super()
		@style_id = style_id
  end

  def initialize_from_xml(xml)
    super(xml)
    @style_id = xml["StyleId"]
  end

  def Clef.new_from_xml(xml)
    ts = Clef.new
    ts.initialize_from_xml(xml)
    ts
  end

	def priority
		7
	end

	# By how many semitones does this clef transpose in LilyPond
	def transposition
		t = CLEF_TRANSPOSITION[@style_id]
		t ? t : 0
	end

  def to_ly
		#return "\\clef " + @style_id + " "
		#def clef2ly(clef)
		return "" unless @style_id
		ly_clef = CLEFS[@style_id]
		if ly_clef 			
			return ly_clef.empty? ? "" : "\\clef #{ly_clef} "
		else
			warning "Unknown clef type: " + @style_id
			return ""
		end
  end
end
