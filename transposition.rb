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
