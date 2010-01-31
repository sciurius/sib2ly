PREAMBLE = "\\version \"2.12.2\"\n"+
  "#(set-global-staff-size 11)\n"+
	"\\layout\n"+
	"{\n"+
	"  \\context\n"+
	"  {\n"+
	"    \\RemoveEmptyStaffContext\n"+
	"    \\override VerticalAxisGroup #'remove-first = ##t\n"+
	"  }\n"+
	"  \\context\n"+
	"  {\n"+
	"    \\RemoveEmptyRhythmicStaffContext\n"+
	"    \\override VerticalAxisGroup #'remove-first = ##t\n"+
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
  "  ragged-bottom=##f\n"+
  "  ragged-last-bottom=##f\n"+
  "  annotate-spacing = ##f\n"+
  "}\n"+
  "fz = #(make-dynamic-script \"fz\")\n"



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
ARTICULATION_TEXT = {
  :Custom3Artic => "",
  :TriPauseArtic => "",
  :PauseArtic => "\\fermata",
  :SquarePauseArtic => "",
  :Custom2Artic => "",
  :DownBowArtic => "\\downbow",
  :UpBowArtic=>  "\\upbow",
  :PlusArtic => "-+",
  :HarmonicArtic => "\\flageolet",
  :MarcatoArtic => "-^",
  :AccentArtic => "->",
  :TenutoArtic => "--",
  :WedgeArtic => "",
  :StaccatissimoArtic => "-|",
  :StaccatoArtic => "-.",
  :Custom1Artic => ""
}
VOICE = {
  1=>"\\voiceOne",
  2=>"\\voiceTwo",
  3=>"\\voiceThree",
  4=>"\\voiceFour"
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

CLEFS = {
  'clef.treble' => 'treble',
  'clef.bass' => 'bass',
  'clef.treble.down.8'=>'"treble_8"',
  'clef.alto' => 'alto',
  'clef.tenor' => 'tenor'
}