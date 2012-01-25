#!/usr/bin/env ruby

require 'optparse'
require 'pp'
require 'fileutils'

# Captured from: http://stackoverflow.com/questions/359424/detach-subdirectory-into-separate-git-repository
class GitSplit
  include FileUtils
  
  def run( args )
    options = {
      :source => Dir.pwd,
    }
    
    OptionParser.new {|opts|
      opts.banner =<<-EOB

Usage: #{$0} [OPTIONS] <sub-path> <target-repo>

Splits out a path in an existing Git repository into its own separate Git repository. Optionally, scrubs the
origin repository of that subdirectory.

      EOB

      opts.on( '-D', "--dry-run", "Print commands to be run. DO NOT CHANGE ANYTHING." ){options[:dry_run] = true}
      opts.on( '-E', "--erase", "Erase from the history of the origin Git repository after splitting" ){options[:erase] = true}
      opts.on( '-R', "--remove", "Remove from the origin Git repository after splitting (produce a new commit)" ){options[:remove] = true}
      opts.on( '-S', '--source-repo PATH', "Path to origin Git repository" ){|dir| options[:source] = dir}

      opts.separator("")
      opts.separator("Other Options:")
      opts.separator("")

      opts.on_tail( "-h", "--help", "Print this help message" ){options[:help]=true}

      parsed_args = opts.parse!( args )
      
      if ( !parsed_args || parsed_args.length < 2 )
        puts "You must supply both a sub-path to split out of the origin repository, AND a target repository location!"
        options[:help] = true
      else
        options[:path] = parsed_args[0]
        options[:target] = parsed_args[1]
      end

      if ( options[:source] != Dir.pwd && ( !File.exists( options[:source] ) || !File.directory?( options[:source] ) ) )
        puts "Invalid source repository: '#{options[:source]}'"
        options[:help] = true
      end
      
      if ( options[:help] )
        puts opts
        puts ""
        exit
      end
    }

    puts "Configuration options:\n-------------------------"
    pp options
    puts "-------------------------\n\n"

    split( options )
    remove( options ) if options[:remove]
    erase( options ) if options[:erase]
  end
  
  private
  def split( options )
    ex( "git clone --no-hardlinks #{options[:source]} #{options[:target]}", options )
    
    mkdir_p( options[:target] ) unless File.directory?( options[:target] )
    Dir.chdir( options[:target] ){
      puts "cd #{options[:target]}" if ( options[:dry_run] )
      
      cmds = []
      cmds << "git filter-branch --subdirectory-filter #{options[:path]} HEAD -- --all"
      cmds << "git reset --hard"
      cmds << "rm -rf .git/refs/original/"
      cmds << "git reflog expire --expire=now --all"
      cmds << "git gc --aggressive --prune=now"

      cmds.each {|cmd|
        ex( cmd, options )
      }
    }
  end
  
  def remove( options )
    Dir.chdir( options[:source] ){
      puts "cd #{options[:source]}" if ( options[:dry_run] )
      
      cmds = []
      cmds << "git rm -rf #{options[:path]}"
      cmds << "git commit -am 'Splitting #{options[:path]} out into a separate Git repository'"
      
      cmds.each {|cmd|
        ex( cmd, options )
      }
    }
  end
  
  def erase( options )
    Dir.chdir( options[:source] ){
      puts "cd #{options[:source]}" if ( options[:dry_run] )
      
      ex( "git filter-branch -f --index-filter \"git rm -r -f --cached --ignore-unmatch #{options[:path]}\" --prune-empty HEAD", options )
    }
  end
  
  def ex( cmd, options )
    if ( options[:dry_run] )
      puts cmd
    else
      system( cmd )

      result = $?
      exit result unless result == 0
    end
  end
end

GitSplit.new.run( ARGV )
