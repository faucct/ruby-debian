#!/usr/bin/ruby
# Copyright (c) Fumitoshi UKAI <ukai@debian.or.jp>
# GPL2
require 'debian'
require 'getoptlong'

file = ''
top = '/org/ftp.debian.org/ftp/dists/stable'
arch = Debian::Dpkg.installation_architecture

opts = GetoptLong.new(
  ['--file', '-f', GetoptLong::REQUIRED_ARGUMENT],
  ['--arch', '-a', GetoptLong::REQUIRED_ARGUMENT],
  ['--top', '-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--help', '-h', GetoptLong::NO_ARGUMENT]
)
opts.each do |opt, val|
  case opt
  when '--file' then file = val
  when '--arch' then arch = val
  when '--top' then top = top
  else
    $stderr.puts 'usage: $0 [-a arch] [-t top] [-f file]'
    exit 1
  end
end

packages = Debian::Packages.new
Debian::COMPONENT.collect do |c|
  f = file
  f = "#{top}/#{c}/binary-#{arch}/Packages" if file == ''
  packages += Debian::Packages.new(f)
end

packages.each_package do |p|
  puts "#{p}: " + (p.provides ? ('(=>' + p.provides.join(',') + ')') : '')
  puts p.unmet(packages).each(&:to_s)
end
