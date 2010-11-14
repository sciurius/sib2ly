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
require 'options'
require 'version'

require 'translatable'
require 'constants'
#require 'benchmark'
require 'score'
require 'assert'
require 'trollop'

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "gems"))

#puts "RUBY_PLATFORM = #{RUBY_PLATFORM}\n"

require 'rainbow'
require 'Win32/Console/ANSI' if RUBY_PLATFORM =~ /win32/ || RUBY_PLATFORM =~ /mingw/
begin
  require 'nokogiri'
rescue gem_error
  error 'Cannot load the \'nokogiri\' gem. Please install it using: gem install nokogiri\n'
  return
end


#include Benchmark
require 'profiler'
exit if Object.const_defined?(:Ocra)

#[NilClass, FalseClass, TrueClass, Fixnum, Symbol].each do |klass|
#  klass.send(:define_method, :dup) { self }
#  klass.send(:define_method, :clone) { self }
#end


class LilypondFile
  attr_accessor :file
  def initialize(file)
    @file = file
  end
  def <<(string)
    file.write(string)
  end
end

# Global output LilyPond file
$ly = nil

def ly(string = nil)
  $ly << string if string
  $ly << "\n"
end


logo = "SIB2LY v" + VERSION_MAJOR + "." + VERSION_MINOR + \
  "  Sibelius to LilyPond translator    (c) 2010 Kirill Sidorov\n\n"
$opts = Trollop::options do
  version logo
  banner logo + "Usage: ruby #{File.basename($0)} [options] filename\n\n"
  opt :output,	"Output file name", :type => String
  #  opt :concise, "Produce more concise output"
  opt :list, 		"List staves only and exit"
  opt :staff,		"Process the specified staff only", :type => :int
  opt :info, 		"Display score information"
  opt :verbose, "Display verbose mesages"
  opt :pitches, "Collect pitch statistics"
end

$config = Options.new

$opts[:input] = ARGV.pop

puts logo

if !$opts[:input]
  error "Invalid input file name."
  Process.exit
end


puts "Reading the score from #{$opts[:input]}..."
fin = File.new($opts[:input], 'r')
sib = Nokogiri.XML(fin)
score = Score.new
score.from_xml(sib.root)

if $opts[:list]
  score.list_staves
  Process.exit
end

puts "Applying magic..."
score.process


if $opts[:info] 
  # Display score information only
  puts score.info
else
  if $opts[:pitches]
    puts score.pitch_classes
  else
    # This is the main mode of operation: output the LilyPond file

    # Generate the output file name it automatically unless it has been provided
    $opts[:output] = make_out_filename($opts[:input]) unless $opts[:output]
    
    puts "Writing the masterpiece to #{$opts[:output]}"
    File.open($opts[:output], 'w') do |file|
      $ly = LilypondFile.new(file)
      score.to_ly
    end
    puts "Done ;-P"
  end
end

