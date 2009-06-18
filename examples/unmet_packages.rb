#!/usr/bin/ruby
# Copyright (c) Fumitoshi UKAI <ukai@debian.or.jp>
# GPL2
require 'debian'
require 'getoptlong'

file=''
top='/org/ftp.debian.org/ftp/dists/stable'
arch=Debian::Dpkg.installation_architecture

opts = GetoptLong.new(
		      ["--file", "-f", GetoptLong::REQUIRED_ARGUMENT],
		      ["--arch", "-a", GetoptLong::REQUIRED_ARGUMENT],
		      ["--top", "-t", GetoptLong::REQUIRED_ARGUMENT],
		      ["--help", "-h", GetoptLong::NO_ARGUMENT])
opts.each {|opt,val|
  case opt
  when "--file" then file = val
  when "--arch" then arch = val
  when "--top" then top = top
  else
    $stderr.puts "usage: $0 [-a arch] [-t top] [-f file]"
    exit 1
  end
}

packages = Debian::Packages.new
Debian::COMPONENT.collect {|c|
  f = file
  if file == ""
    f = "#{top}/#{c}/binary-#{arch}/Packages"
  end
  packages += Debian::Packages.new(f)
}

packages.each_package {|p|
  puts "#{p}: " + (p.provides ? ("(=>" + p.provides.join(",") + ")") : "")
  puts p.unmet(packages).each {|u| u.to_s }
}
