#!/usr/bin/ruby

require 'optparse'

@parser = OptionParser.new
@update = false

@parser.on( '-u', '--update', 'Update SVN directories after cleanup.' ) {@update = true}

@dirs = @parser.parse( *ARGV )

@file_list = nil

if @dirs.size == 0

  STDOUT.puts "Cleanup on current directory."
  @file_list = `svn status`
  @dirs << '.'

else

  @dirs.each do |dir|

    STDOUT.puts "Cleanup on #{dir}"
    @file_list = `svn status`

  end

end

@file_list.each_line do |line|

  line = line.chomp
  
  if line =~ /[~!?]\s+(.+)/

    file = $1.chomp

    STDOUT.puts "Removing: #{file}"
    STDOUT.puts `rm -rf #{file}`

  end

end

STDOUT.puts "Updating #{@dirs.join( ' ' )}" if @update
STDOUT.puts `svn up #{@dirs.join( ' ' )}` if @update


