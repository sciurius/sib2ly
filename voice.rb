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

require 'transposition'
require 'relative'
require 'timesignature'

class Voice
  attr_accessor :bars, :spanners, :voice, :fn, :staff, :has_obj
  def initialize(voice)
    @voice = voice
    @bars = []
    @nr_count = 0
    @staff = nil
  end

  def self.filter_copy(staff, voice, bars, &fun)
    v = self.new(voice)
    v.voice = voice
    v.staff = staff
    @has_obj = false;
    bars.each_with_index do |bar, idx|
      v.bars << Bar.copy(bar, fun, v)
      @has_obj = true unless v.bars.last.objects.select{|obj| fun.call(obj)}.length.zero?
      v.bars.last.bar_voice = voice
      v.bars.last.prev = (idx > 0 ? v.bars[idx - 1] : nil)
    end
    v
  end

  def [](index)
    @bars[index]
  end

  def nr_count
    @bars.inject(0){|sum, bar| sum += bar.nr_count}
  end

  def contains_music?
    return bars.find do |bar|
      bar.contains_music?
    end ? true : false
  end

  def first_note
    for bar in @bars
      for obj in bar.objects
        if obj.is_a?(NoteRest) and (not obj.is_rest?)# and (not obj.grace)
          #  return obj.grace_notes.first.lowest if obj.grace_notes.first
          return obj.lowest
        end
      end
    end
    return nil
  end

  def link_notes
    #  for each note, compute the preceeding note from which octavation is derived
    prev_note = nil

    @bars.each do |bar|
      #bar.objects.select{|obj| obj.is_a?(NoteRest) and (not obj.is_rest?) and (not obj.grace)}.each do |obj|
      bar.objects.select{|obj| obj.is_a?(NoteRest) and (not obj.is_rest?) and (not obj.hidden)}.each do |obj|
        obj.notes.each do |note|
          note.previous_note = prev_note
          prev_note = note
        end
        #    if not (obj.grace)
        prev_note = obj.lowest if obj.is_chord?
        #   end
      end
    end
  end

	def get_noterests
		noterests = []
		@bars.each do |bar|
			noterests += bar.objects.select{|obj| obj.is_a?(NoteRest)}
		end
		noterests
	end

	def detect_transpositions
		noterests = get_noterests
		nonrests = noterests.select {|obj| not obj.is_rest?}
		return if nonrests.empty?
		nonrests.each do |nr|
			prev = nr.prev_non_rest
			if prev
				if prev.transposition != nr.transposition
					tb = TranspositionBegin.new(nr.transposition)
					tb.position = nr.position
					te = TranspositionEnd.new
					te.position = prev.position_after
          nrb = nr.grace_notes.length ? nr.grace_notes.first : nr
					rb = RelativeBegin.new(nrb.lowest)
					rb.position = nr.position
					re = RelativeEnd.new
					re.position = prev.position_after
					prev.bar.add(te)
					nr.bar.add(tb)
					prev.bar.add(rb)
					nr.bar.add(re)

          #					prev.ends_transposition = true
          #					nr.begins_transposition = true
				else
          #					prev.ends_transposition = false
          #					nr.begins_transposition = false
				end
			else
				# This is the first non-rest. It does not end a transposition.
				# It or the first NoteRest begins a transposition.
				# nr.begins_transposition = true
        #				noterests.first.begins_transposition = true
				fn = noterests.first
				tb = TranspositionBegin.new(nonrests.first.transposition)
				tb.position = fn.position
        nrb = nonrests.first.grace_notes.length ? nonrests.first.grace_notes.first : nonrests.first
				rb = RelativeBegin.new(nrb.lowest)
				rb.position = fn.position
				fn.bar.add(tb)
				fn.bar.add(rb)
        #				nr.ends_transposition = false
			end
		end
    #		noterests.last.ends_transposition = true
		ln = noterests.last
		te = TranspositionEnd.new
		te.position = ln.position_after
		re = RelativeEnd.new
		re.position = ln.position_after
		ln.bar.add(te)
		ln.bar.add(re)
	end

  def link_noterests
    # Link NoteRests
    prev_nr = nil
    @bars.each do |bar|
      bar.objects.select{|obj| obj.is_a?(NoteRest) and (not obj.grace)}.each do |obj|
        obj.prev = prev_nr
        prev_nr = obj
      end
    end
  end

  def detect_phrasing_slurs(spanners)
    # Detect phrasing (overlapping) slurs
    slurs = spanners.select{|sp| sp.is_a?(Slur)}
    slurs.each do |this|
      slurs.each do |other|
        if this != other and
            (
            (
              (this.start_bar_number < other.start_bar_number) or
                (this.start_bar_number == other.start_bar_number and this.nr_begin.position <= other.nr_begin.position)
            ) and
              (
              (this.end_bar_number > other.end_bar_number) or
                (this.end_bar_number == other.end_bar_number and this.nr_end.position >= other.nr_end.position)
            )
          )
          this.is_phrasing = true
          this.text_begin = "\\("
          this.text_end = "\\)"
        end
      end
    end
  end

	# For each NoteRest, count under how many slurs it is
  def detect_slurred_noterests(spanners)
    slurs = spanners.select{|sp| sp.is_a?(Slur)}
    slurs.each do |slur|
      slurred_nr = noterests_under_spanner(slur)
      slurred_nr.each{|nr| nr.slurred += 1}
    end
  end

	# Return an array of NoteRests that are under a given spanner
  def noterests_under_spanner(sp)
    result = []
    bb = bars[sp.start_bar_number-1..sp.end_bar_number-1] # bars affected by the spanner 
    bb.each do |b|
      note_rests = b.objects.select{|obj| obj.is_a?(NoteRest)}
      note_rests.each do |nr|
        is_in = false
        if sp.start_bar_number != sp.end_bar_number
          # line spans multiple bars
          if (b.number > sp.start_bar_number and b.number < sp.end_bar_number)
            # nr is in some bar in the middle
            is_in = true
          elsif b.number == sp.start_bar_number
            # nr is in the first bar
            is_in = true if nr.position >= sp.position
          elsif b.number == sp.end_bar_number
            # nr is in the last bar
            is_in = true if nr.position <= sp.end_position
          end
        else
          # line is confined to one bar
          is_in = true if nr.position >= sp.position and nr.position <= sp.end_position
        end
        result << nr if is_in
      end
    end
    result
  end

  def get_spanners
    sp = []
    @bars.each do |bar|
      sp += bar.objects.select do |obj|
        obj.is_a?(Spanner) and !obj.hidden
      end
    end
    sp
  end

  def assign_spanners
    # Find all spanners
    @spanners = get_spanners

    # Find ottava lines
    ottavas = @spanners.select{|sp| sp.is_a?(OctavaLine)}

    # Sort spanners: ottava lines have the lowest priority
    @spanners -= ottavas

    @spanners.each do |sp|
      # Compute the first and last NoteRest affected by the spanner
      bar_begin = @bars[sp.start_bar_number - 1]
      bar_end = @bars[sp.end_bar_number - 1]
      sp.nr_begin = bar_begin.get_noterest_at(sp.position)
      nearest_nr, dist = bar_end.get_nearest_noterest(sp.end_position, true)
      sp.nr_end = nearest_nr
      if sp.end_bar_number < @bars.length
        nearest_nr_next_bar, dist_next_bar = @bars[sp.end_bar_number].get_nearest_noterest(0, true)
        if dist > dist_next_bar + bar_end.length - sp.end_position
          sp.nr_end = nearest_nr_next_bar
        end
      end

      # spanner begins and ends on the same note
      if sp.nr_begin and sp.nr_end
        unless (sp.nr_begin == sp.nr_end)
          sp.nr_begin.begins_spanners << sp
          sp.nr_end.ends_spanners << sp
        else
          # this is a trill on one note, without a line
          if sp.is_a?(Trill)
            sp.text_begin = "\\trill "
            sp.text_end = ""
            sp.nr_begin.begins_spanners << sp
            sp.nr_end.ends_spanners << sp
          elsif
            sp.is_a?(ArpeggioLine) or sp.is_a?(OctavaLine)
            sp.nr_begin.begins_spanners << sp
            sp.nr_end.ends_spanners << sp
          elsif !sp.is_a?(Slur)
            sp.nr_begin.begins_spanners << sp
            sp.nr_end.ends_spanners << sp
            sp.text_end = " s1*0 " + sp.text_end
          end
        end
      end
    end

    detect_phrasing_slurs(spanners)
    detect_slurred_noterests(spanners)

    ottavas.each do |ot|
      transposed_nr = noterests_under_spanner(ot)
      unless transposed_nr.empty?
        ot.nr_begin = transposed_nr.first
        ot.nr_end = transposed_nr.last
        ot.nr_begin.begins_spanners << ot
        ot.nr_end.ends_spanners << ot
        transposed_nr.each{|nr| nr.transpose_octave(ot.ottavation)}
      end
    end
    @spanners += ottavas

  end
  
  def assign_time_signatures
    prev = nil
    for bar in @bars
      ts = bar.objects.find{|obj| obj.is_a?(TimeSignature)}
      prev = ts if ts
      bar.time_signature = prev
    end
  end

  def process
    @bars.each{|bar| bar.delete_empty_texts}
    @bars.each{|bar| bar.fix_empty_bar(@voice)}

    link_notes
#    link_noterests
    @fn = first_note
    @bars.each{|bar| bar.process}
 #   link_noterests
    #count_nr

    assign_spanners
    assign_time_signatures
#    handle_start_repeat_barlines
    convert_slurs_over_grace
		detect_transpositions
    #puts @nr_count
  end

  #convert slurs over slurred grace notes to phrasing
  def convert_slurs_over_grace
    slurs = spanners.select{|sp| sp.is_a?(Slur)}
    slurs.each do |slur|
      slurred_nr = noterests_under_spanner(slur)
      conv = false
      slurred_nr.each do |nr|
        conv = true if nr.grace_slurred
      end
      slur.is_phrasing = conv
    end
  end

  def prev_bar(bar)
    idx = bars.index(bar)
    return nil if idx.nil? or idx.zero?
    return bars[idx - 1]
  end

  def next_bar(bar)
    idx = bars.index(bar)
    return nil if idx.nil? or idx.eql?(bars.length-1)
    return bars[idx + 1]
  end

  def to_ly
    v = brackets("{\n", "}") do |s|
      @bars.each do |bar|
        #puts bar.number
        s << bar.to_ly
      end
      s
    end
    v
  end

  def to_s
    "#{voice} (#{self.class})"
  end
end
