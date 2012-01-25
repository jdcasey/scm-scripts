#!/usr/bin/ruby

system( "svn resolved `svn status | grep '^C ' | awk '{print $2}'`" )
system( "svn resolved `svn status | grep '^ C ' | awk '{print $2}'`" )