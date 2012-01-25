#!/usr/bin/ruby

require 'fileutils'

include FileUtils

while ( !File.exists?( '.git' ) )
  cd( '..' )
end

change_marker = 'Changes not staged'
found_change_line = false
count = 0

`git status | grep -E '#{change_marker}|deleted:'`.each_line do |line|
  if ( !found_change_line )
    if ( line[change_marker] != nil )
      found_change_line = true
    end
    
    next
  end
  
  file = line.chomp
  if ( file =~ /#\s+deleted:\s+(.+)/)
    file = $1
  else
    puts "Bad input line: '#{line.chomp}'"
    next
  end
  
  system( "git rm '#{file}'" )
  count += 1
end

puts "Added #{count} deleted files to pending Git commit."