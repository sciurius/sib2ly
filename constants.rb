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

PREAMBLE = "\\version \"2.12.2\"\n"+
	"#(set-global-staff-size 16)\n"+
	"\\layout\n"+
	"{\n"+
	"  \\context\n"+
	"  {\n"+
	"    \\RemoveEmptyStaffContext\n"+
	"    \\override VerticalAxisGroup #'remove-empty = ##f\n"+
  "  }\n"+
	"  \\context\n"+
	"  {\n"+
	"    \\RemoveEmptyRhythmicStaffContext\n"+
	"    \\override VerticalAxisGroup #'remove-empty = ##f\n"+
  "  }\n"+
	"% \\context { \\Staff \\set hairpinToBarline = ##t }\n"+
  "  \\context { \\Staff \\override VerticalAxisGroup #'minimum-Y-extent = #'(-3.0 . 3.0) }\n"+
  "  \\context { \\Score \\override SpacingSpanner #'base-shortest-duration = #(ly:make-moment 1 15) }\n"+
  "  \\context { \\Score\n"+
	"  \\override BarNumber #'padding = #2\n"+
  "  }\n"+
	"} % Layout\n\n"+
	"\\paper\n"+
	"{\n"+
	"  short-indent=1\\cm\n"+
	"  page-top-space=0\\cm\n"+
	"  ragged-bottom=##t\n"+
  "  ragged-last-bottom=##f\n"+
  "  annotate-spacing = ##f\n"+
  "}\n"+
	"fz = #(make-dynamic-script \"fz\")\n"+
  "ffp = #(make-dynamic-script \"ffp\")\n"+
"sff = #(make-dynamic-script \"sff\")\n"

# Mapping between common dynamic marks ("expression") in Sibelius and
# their LilyPond counterparts
EXPRESSION = {
	"f" => "\\f",
	"ff" => "\\ff",
	"fff" => "\\fff",
	"ffff" => "\\ffff",
	"p" => "\\p",
	"pp" => "\\pp",
	"ppp" => "\\ppp",
	"pppp" => "\\pppp",
	"mf" => "\\mf",
	"mp" => "\\mp",
	"sf" => "\\sf",
	"fz" => "\\fz",
  "ffp" => "\\ffp",
  "sff" => "\\sff"
}

# Symbolic names for Sibelius articulation flags.
ARTICULATION_BITS = {
	:Custom3Artic => 15,
	:TriPauseArtic => 14,
	:PauseArtic => 13,
	:SquarePauseArtic => 12,
	:Custom2Artic => 11,
	:DownBowArtic => 10,
	:UpBowArtic=> 9,
	:PlusArtic => 8,
	:HarmonicArtic => 7,
	:MarcatoArtic => 6,
	:AccentArtic => 5,
	:TenutoArtic => 4,
	:WedgeArtic => 3,
	:StaccatissimoArtic => 2,
	:StaccatoArtic => 1,
	:Custom1Artic => 0}

# Mapping between various articulation types and the LilyPond commands
# to typeset them.
ARTICULATION_TEXT = {
  :Custom3Artic => "",
  :TriPauseArtic => "\\shortfermata",
  :PauseArtic => "\\fermata",
  :SquarePauseArtic => "\\longfermata",
  :Custom2Artic => "",
  :DownBowArtic => "\\downbow",
  :UpBowArtic=>  "\\upbow",
  :PlusArtic => "-+",
  :HarmonicArtic => "\\flageolet",
  :MarcatoArtic => "-^",
  :AccentArtic => "->",
  :TenutoArtic => "--",
  :WedgeArtic => "-|",
  :StaccatissimoArtic => "-|",
  :StaccatoArtic => "-.",
  :Custom1Artic => ""
}

# Symbolic names for polyphonic voices
VOICE = {
  1 => "\\voiceOne",
  2 => "\\voiceTwo",
  3 => "\\voiceThree",
  4 => "\\voiceFour"
}

VOICE_NAMES = {
  1 => 'one',
  2 => 'two',
  3 => 'three',
  4 => 'four'
}

DIGITS = {
  "0"=>"Zero",
  "1"=>"I",
  "2"=>"II",
  "3"=>"III",
  "4"=>"IV",
  "5"=>"V",
  "6"=>"VI",
  "7"=>"VII",
  "8"=>"VIII",
  "9"=>"XI"
}

# Mapping between Sibelius note names in tempo texts and their corresponding
# duration values
TEMPO_NOTE = {
  "W" => "\\breve",
  "w" => "1",
  "h" => "2",
  "q" => "4",
  "e" => "8",
  "x" => "16",
  "y" => "32"
}


# Number of semitones by which clefs in LilyPond transpose the music
CLEF_TRANSPOSITION = {
  'clef.treble' => 0,
  'clef.bass' => 0,
  'clef.treble.down.8'=> -12,
  'clef.treble.up.8'=> 12,
  'clef.treble.up.15'=> 24,
  'clef.alto' => 0,
  'clef.tenor' => 0,
  'clef.percussion' => 0
}

# Mapping between Sibelius acidentals and their LilyPond counterparts.
ACCIDENTALS = {
  "" => "",
  "-" => "eh",
  "b" => "es",
  "b-" => "eseh",
  "bb" => "eses",
  "+" => "ih",
  "#" => "is",
  "#+" => "isih",
  "x" => "isis",
  "##" => "isis"
}

# Mapping between Sibelius acidentals and the corresponding number of semitones.
ACCIDENTALS_SEMITONES = {
  "" => 0,
  "-" => -1,
  "b" => -1,
  "b-" => -2,
  "bb" => -2,
  "+" => 1,
  "#" => 1,
  "#+" => 2,
  "x" => 2,
  "##" => 2
}

TRANSPOSITION = {
  0 => 'c',
  1 => 'des',
  2 => 'd',
  3 => 'es',
  4 => 'e',
  5 => 'f',
  6 => 'ges',
  7 => 'g',
  8 => 'aes',
  9 => 'a',
  10 => 'bes',
  11 => 'b'
}

# Roman numerals
ROMAN = [
  ["M", 1000],
  ["CM", 900],
  ["D", 500],
  ["CD", 400],
  ["C", 100],
  ["XC", 90],
  ["L", 50],
  ["XL", 40],
  ["X", 10],
  ["IX", 9],
  ["V", 5],
  ["IV", 4],
  ["I", 1]
]

# Mapping between Sibelius (diatonic) note names and their position
# within the octave
DIATONIC = {
  "c" => 0,
  "d" => 1,
  "e" => 2,
  "f" => 3,
  "g" => 4,
  "a" => 5,
  "b" => 6,
  "h" => 6  # Just in case
}

# Max grace to one note
MAXGRACE = 64