#!/usr/bin/ruby -w 

`svn status | grep '^C' | awk '{print $2}'`.each_line do |line|
  
  file = line.chomp
  mr_file = `ls #{file}.merge-right.*`.chomp
  
  puts `rm #{file} && mv #{mr_file} #{file} && svn resolved #{file}`
  
end