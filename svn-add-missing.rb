#!/usr/bin/ruby -w

if ARGV.size == 0

  STDOUT.puts `svn add \`svn status | grep '? ' | awk '{print $2}'\``

else

  ARGV.each do |dir|

    Dir.chdir( dir ){
      STDOUT.puts `svn add \`svn status | grep '? ' | awk '{print $2}'\``
    }

  end

end
