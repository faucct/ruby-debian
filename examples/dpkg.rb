#!/usr/bin/ruby
# 
# dpkg.rb - ruby script dpkg compatible interfaces
# Copyright (c) 2001 Fumitoshi UKAI <ukai@debian.or.jp>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# $Id: dpkg.rb,v 1.5 2001/04/22 16:39:29 ukai Exp $
#

require 'debian'
require 'getoptlong'
include Debian

opts = GetoptLong.new(
		      ["--list", "-l", GetoptLong::NO_ARGUMENT],
		      ["--status", "-s", GetoptLong::NO_ARGUMENT],
		      ["--get-selections", GetoptLong::NO_ARGUMENT],
		      ["--print-avail", GetoptLong::NO_ARGUMENT],
		      ["--listfiles", "-L", GetoptLong::NO_ARGUMENT],
		      ["--search", "-S", GetoptLong::NO_ARGUMENT],
		      ["--help", "-h", GetoptLong::NO_ARGUMENT])
opts.ordering = GetoptLong::REQUIRE_ORDER

def usage
  puts "Usage:"
  puts "  #{$0} --list [<package> ...]"
  puts "  #{$0} --status [<package> ...]"
  puts "  #{$0} --get-selections [<pattern> ...]"
  puts "  #{$0} --print-avail [<package> ...]"
  puts "  #{$0} --listfiles [<package> ...]"
  puts "  #{$0} --search [<pattern> ...]"
  puts "  #{$0} --help"
end

func = Proc.new {|args| $stderr.puts "#{$0}: need an action option"} 
begin
  opts.each {|opt, arg|
    case opt
    when "--list" then func = Proc.new {|args| 
	Dpkg.status(args).each_package {|deb|
	  puts [Deb::SELECTION_ID[deb.selection] +
	    Deb::STATUS_ID[deb.status] +
	    Deb::EFLAG_ID[deb.ok],
	    deb.package,
	    deb.version,
	    deb.description].join(" ")
	}
      }
    when "--status" then func = Proc.new {|args|
	Dpkg.status(args).each_package {|deb|
	  puts deb.info_s
	}
      }
    when "--get-selections" then func = Proc.new {|args|
	Dpkg.selections(args).each_package {|deb|
	  puts [deb.package, deb.selection].join("\t")
	}
      }
    when "--print-avail" then func = Proc.new {|args|
	Dpkg.avail(args).each_package {|deb|
	  puts deb.info_s
	}
      }
    when "--listfiles" then func = Proc.new {|args|
	Dpkg.listfiles(args).each {|dlist|
	  puts dlist
	  puts
	}
      }
    when "--search" then func = Proc.new {|args|
	Dpkg.search(args).each {|m|
	  puts "#{m[0]}: #{m[1]}"
	}
      }
    when "--help" then usage; exit 0
    else raise GetoptLong::InvalidOption      
    end
  }
rescue GetoptLong::InvalidOption
  usage; exit 1
end
func.call(ARGV)
