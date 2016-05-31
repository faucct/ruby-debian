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
  ['--list', '-l', GetoptLong::NO_ARGUMENT],
  ['--status', '-s', GetoptLong::NO_ARGUMENT],
  ['--get-selections', GetoptLong::NO_ARGUMENT],
  ['--print-avail', GetoptLong::NO_ARGUMENT],
  ['--listfiles', '-L', GetoptLong::NO_ARGUMENT],
  ['--search', '-S', GetoptLong::NO_ARGUMENT],
  ['--help', '-h', GetoptLong::NO_ARGUMENT]
)
opts.ordering = GetoptLong::REQUIRE_ORDER

def usage
  puts 'Usage:'
  puts "  #{$PROGRAM_NAME} --list [<package> ...]"
  puts "  #{$PROGRAM_NAME} --status [<package> ...]"
  puts "  #{$PROGRAM_NAME} --get-selections [<pattern> ...]"
  puts "  #{$PROGRAM_NAME} --print-avail [<package> ...]"
  puts "  #{$PROGRAM_NAME} --listfiles [<package> ...]"
  puts "  #{$PROGRAM_NAME} --search [<pattern> ...]"
  puts "  #{$PROGRAM_NAME} --help"
end

func = proc { |_args| $stderr.puts "#{$PROGRAM_NAME}: need an action option" }
begin
  opts.each do |opt, _arg|
    case opt
    when '--list' then func = proc do |args|
                         Dpkg.status(args).each_package do |deb|
                           puts [Deb::SELECTION_ID[deb.selection] +
                                 Deb::STATUS_ID[deb.status] +
                                 Deb::EFLAG_ID[deb.ok],
                                 deb.package,
                                 deb.version,
                                 deb.description].join(' ')
                         end
                       end
    when '--status' then func = proc do |args|
                           Dpkg.status(args).each_package do |deb|
                             puts deb.info_s
                           end
                         end
    when '--get-selections' then func = proc do |args|
                                   Dpkg.selections(args).each_package do |deb|
                                     puts [deb.package, deb.selection].join("\t")
                                   end
                                 end
    when '--print-avail' then func = proc do |args|
                                Dpkg.avail(args).each_package do |deb|
                                  puts deb.info_s
                                end
                              end
    when '--listfiles' then func = proc do |args|
                              Dpkg.listfiles(args).each do |dlist|
                                puts dlist
                                puts
                              end
                            end
    when '--search' then func = proc do |args|
                           Dpkg.search(args).each do |m|
                             puts "#{m[0]}: #{m[1]}"
                           end
                         end
    when '--help' then usage; exit 0
    else raise GetoptLong::InvalidOption
    end
  end
rescue GetoptLong::InvalidOption
  usage; exit 1
end
func.call(ARGV)
