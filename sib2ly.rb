$:.unshift File.dirname(__FILE__)

# SIB2LY    Copyright 2010 Kirill Sidorov
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


require 'rubygems'
require 'util'
require 'version'
require 'nokogiri'
require 'translatable'
require 'noterest'
require 'spanners'
require 'bar'
require 'systemtextitem'
require 'constants'
require 'voice'
require 'benchmark'
require 'instrument'
require 'score'
require 'staff'
require 'note'
require 'tuplet'
require 'barrest'
require 'timesignature'
require 'keysignature'
require 'clef'
require 'tremolo'
require 'specialbarline'
require 'staffgroup'
require 'optparse'
require 'ostruct'
include Benchmark
#require "profile"
exit if Object.const_defined?(:Ocra)

class LilypondFile
  attr_accessor :file
  def initialize(file)
    @file = file
  end
  def <<(string)
    file.write(string)
  end
end

$ly = nil

def ly string
  $ly << string
  $ly << "\n"
end



opt = OpenStruct.new
opt.filename = []
opt.verbose = false
opt.info = false

opts = OptionParser.new do |opts|
  script_name = File.basename($0)

  opts.banner = "Usage: #{script_name} [options] filename"

  opts.separator ""
  opts.separator "Specific options:"
  opts.on("-i", "--info", "Display score information but do not convert") do |i|
    opt.info = i;
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options.verbose = v
  end
  
  opts.separator ""
  opts.separator "Common options:"

  # No argument, shows at tail.  This will print an options summary.
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  # Switch to print the version.
  opts.on_tail("--version", "Show version") do
    puts VERSION_MAJOR.to_s + "." + VERSION_MINOR.to_s
    exit
  end
end

opts.parse!(ARGV)
opt.filename = ARGV.pop

if !opt.filename
  puts "ERROR: Invalid input file name."
	Process.exit
else
  opt.out_file = make_out_filename(opt.filename)
end

 puts "Reading the score..."
 fin = File.new(opt.filename, 'r')
 sib = Nokogiri.XML(fin)
 score = Score.new
 score.from_xml(sib.root);
 puts "Applying magic..."
 score.process


if opt.info
  # display score information
  puts score.info
else
  file = File.open(opt.out_file, 'w')
  $ly = LilypondFile.new(file)
  score.to_ly
  puts "done."
end

# fermata on barrest
# slur direction
# stems
# sometimes keysignature in the previous bar
# stem groupings
# small notes
# slurs with grace notes
# rehearsal letters
# octavation in transposing score
# multiple spanners on one note
## tremolos
# text formatting
## staff types
## grace notes
## tempi
# barlines
# shape notes
# lines
# repeats
# piano centered dynamics
## arpeggio
# parts
# auto key signatures
## fix sync grace notes
# simplify output
# tests
## text below and above staff
# combine scores
# time stamp and score duration
# tremolo как NoteRest
# Sibelius versions

