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

#require 'ftools'

class Options
  attr_reader :options
  #private :options_types, :options_default, :options_descriptions

  def add name, type, default, desc
    @options_types[name] = type
    @options_default[name] = default
    @options_descriptions[name] = desc
    @options[name] = default
  end

  def initialize optfile = nil
    @options_default = {}
    #types: boolean, integer, float, string
    @options_types = {}
    @options_descriptions = {}
    @options = {}

    if optfile.nil? or not File.exists?(optfile)
      optfile = File.dirname(File.expand_path(__FILE__))+'/options.sib2ly'
    end

    add("convert_slurs_over_grace", 'boolean', false, 'Convert slurs over slurred grace to phrasing slurs')

    if File.exists?(optfile)
      read_opts(optfile)
    else
      warning('Options file not exists, using default')
    end
  end

  def read_opts(optfile)
    toparse = ''
    File.open(optfile, 'r') {|file| toparse = file.readlines}
    toparse.each do |line|
      line = line[0...line.index('#')] if line.index('#')
      line.strip!
      next if line == ''
      key, value = line.split('=', 2).map{|p| p.strip}
      warning("Configuration key #{key} not exists!") if @options_default[key].nil?
      case @options_types[key]
      when 'boolean'
        value = !['yes', 'true'].index(value.downcase).nil?
      when 'integer'
        value = value.to_i
      when 'float'
        value = value.to_f
      end
      @options[key] = value
    end
  end

  def [] key
    return @options[key] unless @options[key].nil?
    warning("Option #{key} not exists!")
    return nil
  end
end