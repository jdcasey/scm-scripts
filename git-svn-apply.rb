#!/usr/bin/env ruby

require 'optparse'
require 'tempfile'

class Git2SvnPatcher
  
  def initialize( args=[] )
    @options = {}
    OptionParser.new {|opts|
      opts.on( '-i', "--input=DIR", "Git source directory" ){|dir| @options[:source] = dir}
      opts.on( '-o', "--output=DIR", "SVN target directory" ){|dir| @options[:target] = dir}
      opts.on( '-s', "--subject=SUBJECT", "JIRA issue ID (optional)"){|subject| @options[:subject] = subject}
      opts.on( '-N', "--number=NUM", "Number of commits format as patches (using git format-patch HEAD~N)"){|n| @options[:format_number]=n}
      opts.on( '-D', "--dry-run", "Simulated run (without committing anything!)" ){@options[:dry_run]=true}
      
      opts.on( '-h', "--help", "Print this help message and exit"){
        usage(opts)
        exit 0
      }
      
      opts.parse!(args)
      
      if ( !@options[:source] || !@options[:target] )
        puts "You must specified both input AND output directories!"
        usage(opts)
        exit 1
      end
    }
  end #init
  
  def usage(opts)
    puts opts.to_s
    puts
  end #usage
  
  def apply
    Dir.chdir( @options[:source] ){
      status = `git status`
      if ( status =~ /nothing to commit/ )
        puts "Git repository status is clear. Proceeding."
        
        if ( @options[:format_number] )
          puts "Generating patch files from latest #{@options[:format_number]} commits in #{@options[:source]}..."
          exec( "git format-patch HEAD~#{@options[:format_number]}" )
        end
      else
        puts "Git repository has uncommitted work! Please commit or stash and re-run."
        exit 4
      end
    }
    
    
    Dir.chdir( @options[:target] ) {
      puts "Updating svn working directory..."
      exec( "svn up" )
      
      Dir.glob( File.join( @options[:source], "00*.patch" ) ).each {|f|
        message = ""
        message << "[#{@options[:subject]}] " if @options[:subject]
        
        in_subject = false
        File.open( f ) {|file|
          file.each_line {|l|
            line = l.chomp
            if ( line =~ /Subject: \[PATCH.*\] (.+)/ )
              message << $1
              in_subject = true
            elsif ( in_subject )
              if ( line.length < 1 )
                in_subject = false
                break
              else
                part = line[1..-1]
                message << " " << part
              end
            end
          }
        }
        
        puts "\n\nFound patch: #{File.basename(f)}.\nMessage:\n\n\t#{message}\n\n"
        puts "Patch command:\n\tpatch -p1 < #{f}"
        if ( !prompt( "Apply this patch [Y/n]?", true) )
          exit 2
        end
        
        puts "patch -p1 < #{f}"
        exec( "patch -p1 < #{f}" )
        
        `svn status | grep '^?' | awk '{print $2}'`.each_line {|line|
          path = line.chomp
          exec( "svn add #{path}" )
        }
        
        puts "Accounting for files removed from SVN:"
        `svn status | grep '!' | awk '{print $2}'`.each_line {|line|
          path = line.chomp
          exec( "svn rm --force #{path}" )
        }
        
        puts "\n\n\n\n\nCurrent SVN status:"
        exec( "svn status" )
        puts "\n\n"
        
        message_file = Tempfile.new( "svn-commit" )
        message_file << message
        message_file.flush
        
        message_file_path = message_file.path
        puts "SVN commit command:\n\nsvn ci -F #{message_file_path}\nMessage file contents:\n\n#{File.read(message_file_path)}\n\n"
        if ( !prompt( "Commit this patch [y/N]?", false ) )
          exit 3
        end
        
        puts "svn ci -F '#{message_file_path}'"
        exec( "svn ci -F '#{message_file_path}'" ) unless @options[:dry_run]
      }
    }
    
    if ( @options[:format_number] )
      puts "Cleaning up generated patch files in #{@options[:source]}..."
      Dir.chdir( @options[:source] ){
        exec( "rm -v 00*.patch" )
      }
    end
    
  end
  
  def exec( command )
    system( command )
    ret = $?
    exit ret unless ret == 0
  end
  
  def prompt( message, default=nil )
    response = nil
    begin
      STDOUT.print message
      response = STDIN.gets.chomp
      if ( default != nil && ( !response || response.length < 1 ) )
        response = default
        break
      elsif ( response =~ /(([Tt][Rr][Uu][Ee])|([Yy]([Ee][Ss])?))/ )
        response = true
      elsif ( response =~ /(([Ff][Aa][Ls][Ss][Ee])|([Nn]([Oo])?))/ )
        response = false
      else
        puts "Invalid response."
        response = nil
      end
    end while response == nil
    
    response
  end
  
end #class

Git2SvnPatcher.new(ARGV).apply