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

class Voice
  attr_accessor :bars, :spanners, :voice, :fn
  def initialize(bars, voice)
    @voice = voice
    @bars = []
    @nr_count = 0
    bars.each{|bar| @bars << Bar.new(bar, voice)}
  end

  def [](index)
    @bars[index]
  end

  def nr_count
    @bars.inject(0){|sum, bar| sum+=bar.nr_count}
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
      bar.objects.select{|obj| obj.is_a?(NoteRest) and (not obj.is_rest?) }.each do |obj|
        obj.notes.each do |note|
          note.previous_note = prev_note
          prev_note = note
        end
        #    if not (obj.grace)
        prev_note = obj.lowest if obj.is_chord?
        #   end
      end
    end
    prev_nr = nil
    @bars.each do |bar|
      bar.objects.select{|obj| obj.is_a?(NoteRest) and (not obj.grace)}.each do |obj|
        obj.prev = prev_nr
        prev_nr = obj
      end
    end
  end

  def detect_phrasing_slurs(spanners)
    # detect phrasing slurs
    slurs = spanners.select{|sp| sp.is_a?(Slur)}
    slurs.each do |this|
      slurs.each do |other|
        if this != other and ((this.start_bar_number < other.start_bar_number) or
              (this.start_bar_number == other.start_bar_number and this.nr_begin.position <= other.nr_begin.position) and
              ((this.end_bar_number > other.end_bar_number) or
                (this.end_bar_number == other.end_bar_number and this.nr_begin.position >= other.nr_begin.position)))
          this.is_phrasing = true
          this.text_begin = "\\("
          this.text_end = "\\)"
        end
      end
    end
  end

  def detect_slurred_noterests(spanners)
    slurs = spanners.select{|sp| sp.is_a?(Slur)}
    slurs.each do |slur|
      slurred_nr = noterests_under_spanner(slur)
      slurred_nr.each{|nr| nr.slurred += 1}
    end
  end

  def noterests_under_spanner(sp)
    result = []
    bb = bars[sp.start_bar_number-1..sp.end_bar_number-1] # bars affected by ottava line
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
    spanners = []
    @bars.each do |bar|
      spanners += bar.objects.select do |obj|
        obj.is_a?(Spanner) and !obj.hidden
      end
    end
    spanners
  end

  def assign_spanners
    # Find all spanners
    @spanners = get_spanners

    # Find ottava lines
    ottavas = @spanners.select{|sp| sp.is_a?(OctavaLine)}

    # Sort spanners: ottava lines have lowest precedence
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
    link_notes
    @fn = first_note
    @bars.each{|bar| bar.process}
    #count_nr

    assign_spanners
    assign_time_signatures
    #puts @nr_count
  end

  def to_ly
    # fn = first_note
    if fn
      rel = "\\relative c" + get_octave(35-7, fn.diatonic_pitch - (7 * ((fn.pitch - fn.written_pitch)/12)));
    else
      rel = ""
    end
    s = rel + "{"
    @bars.each do |bar|
      s << bar.to_ly;
    end
    s << "}"
    return s
  end
end