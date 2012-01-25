#!/usr/bin/ruby

origin = ARGV[0]
destination = ARGV[1]

lines = `svn list #{origin}`

lines.each_line do |line|

  file = line.chomp

  if file[file.length] == '/'

    file.rstrip!

  end

  puts "Moving #{origin}/#{file} to #{destination}/#{file}"
  puts `svn mv #{origin}/#{file} #{destination}/#{file}`

end
