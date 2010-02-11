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

