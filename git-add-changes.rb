#!/usr/bin/ruby

require 'fileutils'

include FileUtils

while ( !File.exists?( '.git' ) )
  cd( '..' )
end

change_marker = 'Changes not staged'
found_change_line = false
count = 0

`git status | grep -E '#{change_marker}|modified:'`.each_line do |line|
  if ( !found_change_line )
    if ( line[change_marker] != nil )
      found_change_line = true
    end
    
    next
  end
  
  file = line.chomp
  if ( file =~ /#\s+modified:\s+(.+)/)
    file = $2
  else
    puts "Bad input line: '#{line.chomp}'"
    next
  end
  
  system( "git add '#{file}'" )
  count += 1
end

add_marker = 'Untracked files'
found_add_line = false
`git status`.each_line do |line|
  if ( !found_add_line )
    if ( line[add_marker] != nil )
      found_add_line = true
    end
    
    next
  end
  
  file = line.chomp
  if ( file =~ /#\s+([.a-zA-Z0-9].+)/)
    file = $2
  else
    puts "Bad input line: '#{line.chomp}'"
    next
  end
  
  system( "git add '#{file}'" )
  count += 1
end

puts "Added #{count} new or modified files to pending Git commit."