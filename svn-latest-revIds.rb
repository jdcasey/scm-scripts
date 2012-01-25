#!/usr/bin/ruby

require 'set'

revIds = Set.new

`find . -type f \\! -path '*/.svn/*'`.each_line do |line|
  revIds << `svn info #{line.chomp} | grep 'Last Changed Rev' | awk '{print $4}'`.chomp
end

revIds.to_a.sort!.reverse!.each {|revId| puts revId}
