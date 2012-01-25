#!/usr/bin/env ruby

class ApplyGitPatches
  
  def run
    patch_dir = ARGV[0]

    puts "Applying patches in #{File.expand_path( patch_dir )}:"

    patches = Hash.new
    Dir.chdir(patch_dir){
      Dir.glob( "*.patch").each {|match|
        patches[match[0..3].to_i] = match
      }
    }

    patches.keys.sort.each {|key|
      patch = patches[key]

      path = File.expand_path( File.join( patch_dir, patch ) )
      message = nil

      File.open(path) {|f|
        f.each_line {|line|
          line = line.chomp
          # puts line
          if ( line =~ /Subject: \[PATCH \d+\/\d+\] (.+)/ )
            message = $1
            puts message
          end
        }
      }

      run_or_die( "patch -p1 < #{path}" )

      changes = `svn status`
      changes.each_line {|change|
        change.chomp!
        if ( change && change != '' )
          if ( change =~ /^\?\s+(.+)/ )
            run_or_die( "svn add #{$1}" )
          elsif ( change =~ /^!\s+(.+)/ )
            run_or_die( "svn rm --force #{$1}" )
          end
        end
      }

      if ( message )
      else
        puts "For: #{path}"
        STDOUT.print "Enter commit message: "
        message = STDIN.gets
      end

      # message.gsub!(/\\|'/) { |c| "\\#{c}" }
      
      puts "Applied #{path}"
      puts "Commit message: '#{message}'"
      
      STDOUT.print "Commit? [y/N] "
      if ( STDIN.gets.chomp.downcase == 'y' )
        puts "Committing..."
        run_or_die( "svn ci -m \"#{message}\"")
      end
    }
  end
  
  def run_or_die( cmd )
    puts cmd
    if !system( cmd )
      return_value = $?
      puts
      exit return_value
    end
  end
end

ApplyGitPatches.new.run
