#!/usr/bin/ruby

require 'fileutils'

include FileUtils

while ( !File.exists?( '.git' ) )
  cd( '..' )
end

change_marker = 'Untracked files:'
found_change_line = false
count = 0

`git status`.each_line do |line|
  if ( !found_change_line )
    found_change_line = true if ( line[change_marker] )
    
    next
  end

  next unless found_change_line
  next unless line['#']
  next unless line.size > 2
  next if line =~ /^#\s+\(/
    
  file = line.chomp
  if ( file =~ /#\s+(.+)/)
    file = $1
  else
    puts "Bad input line: '#{line.chomp}'"
    next
  end
  
  system( "rm -rvf '#{file}'" )
  count += 1
end

puts "Deleted #{count} unstaged files."