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

# Display logo and version first
require 'version'
logo = "SIB2LY v" + VERSION_MAJOR + "." + VERSION_MINOR + \
  "  Sibelius to LilyPond translator    (c) 2010--2011 Kirill Sidorov\n\n"
puts logo

require 'rubygems'
require 'util'
require 'options'
require 'translatable'
require 'constants'
#require 'benchmark'
require 'score'
require 'assert'
require 'lyfile'



# Load the gems that we carry in the ./gems folder for portability
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "gems"))
require 'trollop'
require 'rainbow'
require 'Win32/Console/ANSI' if RUBY_PLATFORM =~ /win32/ || RUBY_PLATFORM =~ /mingw/

# The nokogiri gem, as far as I know, has to be built on every platform natively,
# so the best we can do (if nokogiri is absent) is to inform the user how to install it.
begin
  require 'nokogiri'
rescue LoadError
  error "Cannot load the 'nokogiri' gem!\nPlease install it using: gem install nokogiri\n"
  exit
end
# Assume all gems are loaded at this point

#include Benchmark
#require 'profiler'
exit if Object.const_defined?(:Ocra)

$opts = Trollop::options do
  version logo
  banner logo + "Usage: ruby #{File.basename($0)} [options] filename\n\n"
  opt :output,	"Output file name", :type => String
  #  opt :concise, "Produce more concise output"
  opt :list, 		"List staves and exit, do not translate music"
  opt :staves,	"Process only the specified staves", :type => :ints
  opt :info, 		"Display score information, do not translate music"
  opt :verbose, "Display verbose messages"
  opt :pitches, "Collect pitch statistics"
  opt :begin,   "The first bar to process", :type => :int
  opt :end,     "The last bar to process", :type => :int
  opt :compile, "Run LilyPond after conversion"
end

staves_to_process = $opts[:staves]
if staves_to_process
  verbose "I will translate only staves #{staves_to_process}."
else
  verbose "I will translate all staves."
end
$first_bar = $opts[:begin]
$last_bar = $opts[:end]



$config = Options.new
$opts[:input] = ARGV.pop

if !$opts[:input]
  error "Invalid input file name."
  Process.exit
end

puts "Reading the score from #{$opts[:input]}..."
fin = File.new($opts[:input], 'r')
sib = Nokogiri.XML(fin)
score = Score.new
score.from_xml(sib.root, staves_to_process)

if $opts[:list]
  score.list_staves
  Process.exit
end

puts "Applying magic..."
score.process

if $opts[:info] 
  # Display score information only
  puts
  puts "Score information"
  puts "================="
  puts score.info
  Process.exit
end
if $opts[:pitches]
  puts score.pitch_classes
  Process.exit
end

# This is the main mode of operation: output the LilyPond file

# Generate the output file name automatically unless it has been provided
$opts[:output] = make_out_filename($opts[:input]) unless $opts[:output]
    
puts "Writing the masterpiece to #{$opts[:output]}"
File.open($opts[:output], 'w') do |file|
  $ly = LilypondFile.new(file)
  score.to_ly
end
puts "Done ;-P"

if $opts[:compile]
  puts "Running LilyPond..."
  system("lilypond --ps #{$opts[:output]}")
end

