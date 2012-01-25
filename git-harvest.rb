#!/usr/bin/env ruby

count = 1
lines = Array.new
`git log | grep -B 1 -A 4 'Author: John Casey' | grep 'commit' | awk '{printf \"%s~1..%s\\n\", $2, $2}'`.each_line {|line|
  lines << line
}

lines.reverse.each {|line|
  num = "%04d" % count
  cmd = "git format-patch -n --start-number #{count} -o patches #{line}"
  system( cmd )
  count = count+1
}
