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
require 'note'
require 'duration'

class NoteRest < BarObject
  attr_reader :duration, :real_duration, :notes, :articulations, :grace,
    :acciaccatura, :appogiatura, :tuplets, :tied,
    :ends_spanners, :begins_spanners, :texts, :texts_before,
    :single_tremolos, :double_tremolos,
    :ottavation, :beam,
		:ends_bar, :bar
	attr_accessor :begins_transposition, :ends_transposition, :one_voice, :grace_notes, :slurred,
		:ends_tuplet, :lyrics
  def initialize
    @tied = false
    @slurred = 0
    @tuplets = []
    @ends_spanners = []
    @begins_spanners = []
    @texts = []
    @texts_before = []
    @notes = []
    @duration = 0
    @ends_tuplet = 0
    @grace_notes = []
    @lyrics = nil
    @single_tremolos = 0
    @double_tremolos = 0
    @ottavation = 0
  end

  def initialize_copy(source)
    super
    @duration = @duration.dup
    @real_duration = @real_duration.dup if @real_duration
    @texts = @texts.dup
  end

	# Number of semitones by which this NoteRest is transposed in the transposing
  # score. If this is a rest then its transposition is equal to that of a pre-
  # vious non-rest. If this is a rest and there are no previous non-rests, then
  # its transposition is 0.
	def transposition
		if is_rest?
			if prev
        return prev.transposition
			else
				return 0
			end
		else
			notes.first.transposition
		end
	end
	
	def begins_tremolo?
    @begins_tremolo ||= !ends_tremolo? && !double_tremolos.zero? && !rest?
    #		return false if ends_tremolo?
    #		not double_tremolos.zero?
	end

	def ends_tremolo?
    @ends_tremolo ||= prev && prev.begins_tremolo?
	end

  def initialize_from_xml(xml)
    initialize
    super(xml)
    @duration = Duration.new(xml["Duration"].to_i)
    @single_tremolos = xml["SingleTremolos"].to_i
    @double_tremolos = xml["DoubleTremolos"].to_i
    @articulations = xml["Articulations"].to_i
    @grace = xml["GraceNote"].eql?("true")
    @acciaccatura = xml["IsAcciaccatura"].eql?("true")
    @appogiatura = xml["IsAppoggiatura"].eql?("true")
    @beam = xml["Beam"].to_i
    (xml/"Note").each {|note| notes << Note.new(note)}
  end

  def NoteRest.new_from_xml(xml)
    nr = NoteRest.new
    nr.initialize_from_xml(xml)
    nr
  end

  # Returns the preceding NoteRest
  def prev
    bar.prev_noterest(self)
  end

  # Returns the next NoteRest
  def next
    bar.next_noterest(self)
  end

	def tuplets=(tp)
		assert(tp, "Trying to assign nil to tuplets.")
		assert(tp.is_a?(Array), "Trying to assign a non-Array to tuplets.")
		assert((tp.empty? or (tp.inject(true) {|all, obj| all = all and obj.is_a?(Tuplet)})), \
        "Some of the objects in the array of tuplets are not of type Tuplet.")
		@tuplets = tp
	end

	def duration=(d)
    if d.is_a?(Duration)
      @duration = d.clone
    else
      assert(d > 0, "NoteRests must have positive duration.")
      assert(d.to_i == d, "The duration of a NoteRest must be an integer.")
      @duration = Duration.new(d.to_i)
    end
	end

  def real_duration=(d)
    if d.is_a?(Duration)
      @real_duration = d.clone
    else
      assert(d > 0, "NoteRests must have positive duration.")
      assert(d.to_i == d, "The duration of a NoteRest must be an integer.")
      @real_duration = Duration.new(d.to_i)
    end
	end

  def transpose_octave(ottavation)
    @notes.each do |n|
      n.diatonic_pitch += 7 * ottavation
      n.written_diatonic_pitch += 7 * ottavation
    end
    @grace_notes.each{|n| n.transpose_octave(ottavation)}
  end



  def notes_to_ly
    s = ""
    # In concise mode, we need to output the duration after each NoteRest if
    # it is the first NoteRest in the staff, or if its duration differs from
    # that of the previous one, or if it has grace notes attached to it, or
    # if it preceded by a rest.
    need_duration = ((not $opts[:concise]) or
        (not @grace_notes.empty?) or
        (not prev) or
        (prev.duration != duration) or
        (prev.is_rest?))

    # Depending on whether it is a rest, a single note, or a chord...
    case @notes.length
    when 0
      # rest
      if @hidden
        s << "s"
        s << duration.to_ly
      else
        s << "r"
        s << duration.to_ly if need_duration
      end
    when 1
      # single note
      if @hidden
        s << "s"
        s << duration.to_ly
      else
        s << @notes.first.to_ly
        s << duration.to_ly if need_duration
      end
    else
      # chord
      s << "<#{@notes * ' '}>" # Join the anotes, separated by spaces.
      s << @duration.to_ly if need_duration
			# TODO: Hidden chords?
    end
    s
  end
  
	# Typeset grace notes, if any.
  def grace_to_ly
		return "" if @grace_notes.empty?
		s = ""
		# index of the first non-hidden grace note
		first_non_hidden = @grace_notes.index(@grace_notes.find{|obj| !obj.hidden})

		if !first_non_hidden or @slurred > 0
			s << '\grace '
		elsif @grace_notes.first.acciaccatura
			s << '\acciaccatura '
		else
			s << '\appoggiatura '
    end
    if @grace_notes.length > 1
      s << "{"
    end
    @grace_notes.each_with_index do |gn, index|
      s << gn.notes_to_ly + " "
      if (@grace_notes.length > 1) and (first_non_hidden == index) and \
					(first_non_hidden != @grace_notes.length-1)
        s << '['
      end
      if (@grace_notes.length > 1) and (@grace_notes.length-1 == index) and \
					(first_non_hidden) and (first_non_hidden != @grace_notes.length-1)
        s << ']'
      end
    end
    if @grace_notes.length > 1
      s << "} "
    end
    s
  end

	# Output either \oneVoice or one of the \voiceXXX commands, depending
	# on whether this NoteRest is used in a polyphonic circumstances or not.
  def voice_mode_to_ly
    return "" if ends_tremolo?
    s = ""
    # select voice mode
    if (not prev and @one_voice) or (prev and !prev.one_voice and @one_voice)
      s << "\\oneVoice "
    elsif (not prev and not @one_voice) or (prev and prev.one_voice and !@one_voice)
      s << VOICE[@voice] << " " if @voice
    end
    s
  end

  def begin_octavation_to_ly
    return '' if @begins_spanners.empty?
    return @begins_spanners.select{|sp| sp.is_a?(OctavaLine)}.inject('') do |s, sp|
      s << sp.text_begin_before
    end
  end

  def begin_tuplets_to_ly
    # if the NoteRest is the first in a tuplet
    tuplets.select{|tuplet| tuplet.notes.first == self}.inject('') do |s, tuplet|
      s << tuplet.to_ly
    end
  end

  def texts_before_to_ly
    @texts_before.inject(''){|s, text| s << text.to_ly}
  end

  def tremolos_to_ly
    # NOTE: Has side effect, affects duration of the NoteRest
    s = ""
    td = duration.to_i
    if @single_tremolos > 0 and !is_rest?
      td = get_tremolo_duration(duration.to_i, @single_tremolos)
      s << "\\repeat tremolo " << (duration.to_i / td).to_i.to_s << ' '
    elsif begins_tremolo?
      td = get_tremolo_duration(duration.to_i * 2, double_tremolos)
      s << "\\repeat tremolo " << (duration.to_i / td).to_i.to_s << ' {'
    elsif ends_tremolo?
      td = get_tremolo_duration(duration.to_i * 2, prev.double_tremolos)
    end
    self.duration = td
    return s
  end

	def begins_bar
		prev and (prev.bar != bar)	
	end

	# Return the preceding NoteRest that is not a rest, or nil if this is
	# the first NoteRest.
	def prev_non_rest
		return nil unless prev
		if prev.is_rest?
			return prev.prev_non_rest
		else
			return prev
		end
	end

	# Convert the NoteRest to LilyPond syntax
  def to_ly
    s = ""

		# Is this NoteRest in polyphonic mode or single voice mode?
    s << voice_mode_to_ly

		# Is this noterest the first of a series under an ottava line?
    s << begin_octavation_to_ly
    s << begin_tuplets_to_ly
    s << grace_to_ly
    s << texts_before_to_ly
    s << tremolos_to_ly

		# Convert the actual notes
    s << notes_to_ly
		
    # add articulations
    unless is_rest?
      art = Hash[*ARTICULATION_BITS.select{|key, value| \
            (0<(@articulations & (1 << value)))}.flatten]
      art.each{|key, value| s << ARTICULATION_TEXT[key]}
    end

    # add text
    @texts.each{|text| s << text.to_ly}
    #    s << "^\\markup{I}" if one_voice
    #    s << "^\\markup{B}" if begins_tremolo?
    #    s << "^\\markup{E}" if ends_tremolo?

    @begins_spanners.each{|sp| s << sp.text_begin_before if !sp.is_a?(OctavaLine)}

    unless @begins_spanners.empty?
      @begins_spanners.each{|sp| s << sp.text_begin}
    end
    unless @ends_spanners.empty?
      # slurs have priority
      @ends_spanners.each{|sp| s << sp.text_end if sp.is_a?(Slur)}
      @ends_spanners.each{|sp| s << sp.text_end unless sp.is_a?(Slur)}
    end
    s << "~" if @tied
    s << " "
    # close the brace after the second NoteRest in a double tremolo if necessary

    s << '}' if ends_tremolo?

    # close the brace after the last NoteRest in a tuplet, if necessary.
    (@ends_tuplet).times { s << "}" }

    return s
  end

	# Return the position in the Bar just after this NoteRest.
	def position_after
		position + real_duration.duration
	end

  # Determine if only some of the notes are tied
  # 1) If all notes are tied then the NoteRest is tied, but individual notes are not
  # 2) If only some notes are tied, then the NoteRest is not tied
  def determine_ties
    all_notes_tied = @notes.inject(true){|sum, note| sum = sum and note.tied}
    if all_notes_tied and not is_rest?
      # All notes are tied, therefore make the whole NoteRest tied
      # but not the individual notes
      @tied = true
      notes.each{|note| note.tied = false}
    end
  end

	# Compute the sounding duration, taking into account all tuplets
  # to which this NoteRest belongs
  def compute_real_duration
    @real_duration = @duration.clone
    @tuplets.each do |tuplet|
      @real_duration *= tuplet.right
    end
    @tuplets.each do |tuplet|
      @real_duration = Duration.new(@real_duration.duration.to_i/tuplet.left.to_i)
    end
    #@real_duration.duration = @real_duration.duration.round.to_i
    assert(@real_duration.is_a?(Duration))
  end

  def process
    determine_ties
    compute_real_duration
  end

  def is_rest?
    return notes.empty?
  end

  alias :rest? :is_rest?

  def is_chord?
    return @notes.length > 1
  end

	# Return the lowest note in the NoteRest, by absolute pitch.
  def lowest
    return notes.sort{|a, b| a.pitch <=> b.pitch}.first;
  end

  # Determine if this NoteRest overlaps temporally with another.
  def overlaps?(other)
    not (other.position >= position + duration.to_i or
        position >= other.position + other.duration.to_i)
  end

  def to_s
    [notes_to_ly, position.to_s, real_duration.to_i.to_s].join(' ')
  end
end
