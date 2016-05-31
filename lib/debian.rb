#
# debian.rb - ruby interface for dpkg
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
# $Id: debian.rb,v 1.33 2003/10/07 17:07:02 ukai Exp $
#

require 'debian/ar'
require 'debian/utils'
require 'debian_version'

# ruby1.6 does not have Hash.values_at, but ruby1.8 prefers it
unless {}.respond_to? :values_at
  class Hash
    alias values_at indexes
  end
end

module Debian
  class Error < StandardError; end
  COMPONENT = %w(main contrib non-free).freeze

  ################################################################
  module Dpkg
    DPKG = '/usr/bin/dpkg'.freeze
    AVAILABLE_FILE = '/var/lib/dpkg/available'.freeze
    STATUS_FILE = '/var/lib/dpkg/status'.freeze
    PACKAGE_INFO_DIR = '/var/lib/dpkg/info'.freeze

    def status(pkgs = [])
      Packages.new(STATUS_FILE, pkgs) + Packages.new(AVAILABLE_FILE, pkgs, %w(package priority section))
    end

    def selections(pkgs = [])
      Packages.new(STATUS_FILE, pkgs)
    end

    def avail(pkgs = [])
      Packages.new(AVAILABLE_FILE, pkgs)
    end

    def listfiles(pkgs = [])
      Status.new(pkgs).values.collect(&:data)
    end

    def search(pats = [])
      pat = Regexp.new('(' + pats.join('|') + ')')
      r = []
      Dir[File.join(PACKAGE_INFO_DIR, '*.list')].each do |fn|
        pkg = File.basename(fn).gsub(/.list$/, '')
        File.open(fn) do |f|
          f.readlines.grep(pat).collect do |l|
            r.push([pkg, l.chomp])
          end
        end
      end
      r
    end

    def compare_versions(a, rel, b)
      Debian::Version.cmp_version(a, rel, b)
    end

    def field(debfile, fld = [])
      deb = DpkgDeb.load(debfile)
      if !fld.empty?
        flv = []
        fld.each do |fl|
          flv.push(deb[fl])
        end
        flv
      else
        deb
      end
    end

    def architecture
      # gcc --print-libgcc-file-name => archtable
      `#{DPKG} --print-architecture`.chomp!
    end

    def gnu_build_architecture
      # gcc --print-libgcc-file-name => archtable
      `#{DPKG} --print-gnu-build-architecture`.chomp!
    end

    def installation_architecture
      # dpkg build time configuration?
      `#{DPKG} --print-installation-architecture`.chomp!
    end
    module_function :status, :selections, :avail
    module_function :listfiles, :search
    module_function :compare_versions, :field
    module_function :architecture
    module_function :gnu_build_architecture, :installation_architecture
  end

  module DpkgDeb
    DEBFORMAT_VERSION = "2.0\n".freeze

    def deb?(debfile)
      f = Debian::Ar.new(debfile)
      res = (f.open('debian-binary').read == DEBFORMAT_VERSION)
      f.close
      return res
    rescue NameError, Debian::ArError
      false
    end

    def assert_deb?(debfile)
      unless deb?(debfile)
        raise Debian::Error, "`#{debfile}' is not a debian format archive"
      end
    end

    def control(debfile)
      load(debfile).control
    end

    def data(debfile)
      load(debfile).data
    end

    def load(debfile)
      info = ''
      ar = Debian::Ar.new(debfile)
      ar.open('control.tar.gz') do |ctz|
        Debian::Utils.gunzip(ctz) do |ct|
          Debian::Utils.tar(ct, Debian::Utils::TAR_EXTRACT, '*/control') do |fp|
            info = fp.readlines.join('')
            fp.close
          end
          ct.close
        end
      end
      ar.close
      deb = Deb.new(info)
      deb.filename = File.expand_path(debfile, Dir.getwd)
      deb.freeze
      deb
    end

    module_function :deb?, :assert_deb?
    module_function :control, :data
    module_function :load
  end

  ################################################################
  class FieldError < Error; end
  module Field
    def parse_fields(c, rf = [], wf = [])
      @info_s = c
      @info = {}
      @fields = []
      cs = c.split("\n")
      field = ''
      wf += rf unless wf.empty?
      while (line = cs.shift)
        line.chomp!
        if /^\s/ =~ line
          if field == ''
            raise Debian::FieldError,
                  "E: invalid format #{line} in #{line}"
          end
          if wf.empty? || wf.find { |f| f.capitalize == field }
            @info[field] += "\n" + line
          end
        elsif /(^\S+):\s*(.*)/ =~ line
          (field = Regexp.last_match(1)).capitalize!
          if wf.empty? || wf.find { |f| f.capitalize == field }
            @fields.push(field)
            if @info[field]
              raise Debian::FieldError,
                    "E: duplicate control info #{field} in #{line}"
            end
            @info[field] = Regexp.last_match(2).strip
          end
        end
      end
      rf.each do |f|
        unless @info[f.capitalize]
          raise Debian::FieldError,
                "E: required field #{f} not found in #{c}"
        end
      end
      @package = @info['Package']
      @version = @info['Version'] || ''
      @maintainer = @info['Maintainer'] || ''
      @info
    end

    def fields
      if block_given?
        @fields.each do |f|
          yield f
        end
      else
        @fields
      end
    end

    def [](field)
      @info[field.capitalize]
    end

    def to_s
      "#{@package} #{@version}"
    end

    def ===(deb)
      deb && package == deb.package
    end

    def <(deb)
      self === deb &&	Dpkg.compare_versions(version, '<<', deb.version)
    end

    def <=(deb)
      self === deb && Dpkg.compare_versions(version, '<=', deb.version)
    end

    def ==(deb)
      self === deb && Dpkg.compare_versions(version, '=', deb.version)
    end

    def >=(deb)
      self === deb && Dpkg.compare_versions(version, '>=', deb.version)
    end

    def >(deb)
      self === deb && Dpkg.compare_versions(version, '>>', deb.version)
    end
    attr_reader :info_s, :info, :package, :version, :maintainer
  end

  ################################################################
  class DepError < Error; end
  class Dep
    # Dependency: <term> [| <term>]*
    DEP_OPS = ['<<', '<=', '=', '>=', '>>'].freeze
    DEP_OPS_RE = Regexp.new('([-a-z0-9.+]+)\\s*\\(\\s*(' + DEP_OPS.join('|') + ')\\s*([^)]+)\\)')

    class Unmet
      def initialize(dep, deb)
        # `deb' doesnt satisfy `dep' dependency
        # deb == nil, then such package not found
        @package = nil
        @relation = nil
        @dep = dep
        @deb = deb
      end
      attr_reader :dep, :deb
      attr_reader :package

      def package=(p)
        raise DepError, 'E: trying package override' if @package
        @package = p
      end

      attr_reader :relation

      def relation=(r)
        raise DepError, 'E: trying relation override' if @relation
        @relation = r
      end

      def to_s
        s = ''
        s += "#{@package} " if @package
        s += "#{@relation} " if @relation
        s += "#{dep} unmet "
        if @deb
          s += @deb.to_s
          s += " (provides #{dep.package})" if @deb.package != dep.package
        else
          s += "#{dep.package} not found"
        end
        s
      end

      def ==(unmet)
        @package == unmet.package &&
          @relation == unmet.relation &&
          @dep == unmet.dep &&
          @deb == unmet.deb
      end
    end

    class Term
      # Dependency term: <package> [(<op> <version>)]
      def initialize(package, op = '', version = '')
        @package = package
        @op = op
        @version = version
      end
      attr_reader :package, :op, :version
      def to_s
        s = @package
        s += " (#{@op} #{@version})" if @op != '' && @version != ''
        s
      end

      def satisfy?(deb)
        case @op
        when '<<' then return deb < self
        when '<=' then return deb <= self
        when '=' then return deb == self
        when '>=' then return deb >= self
        when '>>' then return deb > self
        when '' then
          return true if deb === self
          deb.provides.each { |pp| return true if pp == @package }
          return false
        else
          raise Debian::DepError, "E: unknown operation #{@op}"
        end
      end

      def unmet(packages)
        us = []
        p = packages.provides(@package)
        return [Unmet.new(self, nil)] if !p || p.empty?
        p.each do |deb|
          return [] if satisfy?(deb)
          u = Unmet.new(self, deb)
          us.push(u)
        end
        us.flatten.compact
      end

      def ==(t)
        @package == t.package &&
          @op == t.op &&
          @version == t.version
      end
    end ## Dep::Term

    def initialize(deps, rel)
      @deps = []
      @rel = rel
      deps.split('|').each do |dep|
        dep.strip!
        # puts DEP_OPS_RE.source
        if DEP_OPS_RE =~ dep
          # puts "P:#{$1} R:#{$2} V:#{$3}"
          @deps.push(Term.new(Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3)))
        else
          # puts "P:#{dep}"
          @deps.push(Term.new(dep))
        end
      end
    end

    def to_s
      "#{@rel} " + @deps.join(' | ')
    end

    def unmet(packages)
      us = []
      @deps.each do |dep|
        u = dep.unmet(packages)
        # if one of dep is satisfied, it's ok. OR relations
        return [] if u.empty?
        us.push(u)
      end
      us
    end

    def satisfy?(deb)
      @deps.each do |dep|
        return true if dep.satisfy?(deb)
      end
      false
    end

    def include?(deb)
      @deps.each do |dep|
        return true if deb === dep
      end
      false
    end
  end

  ################################################################
  class Deb
    include Field
    @@reqfields = ['package'].collect(&:capitalize)
    # 'version', 'maintainer', 'description': -- not used in status if remove
    # 'section','priority': not used in status in some case
    # 'architecture': not used in status
    @@dependency = ['depends', 'recommends', 'suggests', 'pre-depends',
                    'enhances', 'conflicts', 'replaces'].collect(&:capitalize)

    # dpkg/lib/parsehelp.c, dpkg/main/enquiry
    SELECTION_ID = {
      'unknown' => 'u',
      'install' => 'i',
      'hold' => 'h',
      'deinstall' => 'r',
      'purge' => 'p'
    }.freeze
    EFLAG_ID = {
      'ok' => ' ',
      'reinstreq' => 'R',
      'hold' => '?',
      'hold-reinstreq' => '#'
    }.freeze
    STATUS_ID = {
      'not-installed' => 'n',
      'unpacked' => 'U',
      'half-configured' => 'F',
      'installed' => 'i',
      'half-installed' => 'H',
      'config-files' => 'c',
      #      "postinst-failed" backward compat?
      #      "removal-failed"  backward compat?
    }.freeze

    # XXX: files in maintainer scripts from *.deb
    def initialize(info_s, fields = [])
      parse_fields(info_s, @@reqfields, fields)
      @source = @info['Source'] || @package
      @provides = []
      if @info['Provides']
        @provides = @info['Provides'].split(',').each(&:strip!)
      end
      @deps = {}
      # puts "P: #{@package}"
      @selection = 'unknown'
      @ok = 'ok'
      @status = 'not-installed'
      @selection, @ok, @status = @info['Status'].split if @info['Status']
      if @description = @info['Description']
        @description = @description.sub(/\n.*/m, '')
      end
      @filename = nil
      @artab = nil
      @control = []
      @data = []
    end
    attr_reader :package, :source, :version, :provides
    attr_reader :status, :ok, :selection, :description
    attr_reader :filename, :control, :data
    def update_deps
      @@dependency.each do |rel|
        # puts "D: #{rel} => #{@info[rel]}"
        next if @deps[rel]
        next unless @info[rel]
        @deps[rel] = []
        @info[rel].split(',').each do |deps|
          deps.strip!
          # puts "DD: #{deps}"
          @deps[rel].push(Dep.new(deps, rel))
        end
      end
    end
    private :update_deps

    def deps(rel)
      update_deps
      @deps[rel.capitalize] || []
    end

    # selections
    def unknown?
      @selection == 'unknown'
    end

    def install?
      @selection == 'install'
    end

    def hold?
      @selection == 'hold'
    end

    def deinstall?
      @selection == 'deinstall'
    end

    def remove?
      deinstall?
    end

    def purge?
      @selection == 'purge'
    end

    # ok?
    def ok?
      @ok == 'ok'
    end

    # status
    def not_installed?
      @status == 'not-installed'
    end

    def purged?
      not_installed?
    end

    def unpacked?
      @status == 'unpacked'
    end

    def half_configured?
      @status == 'half-configured'
    end

    def installed?
      @status == 'installed'
    end

    def half_installed?
      @status == 'half-installed'
    end

    def config_files?
      @status == 'config-files'
    end

    def config_only?
      config_files?
    end

    def removed?
      config_files? || not_installed?
    end

    def need_fix?
      !ok? || !(not_installed? || installed? || config_files?)
    end

    def need_action?
      !((unknown? && not_installed?) ||
  (install? && installed?) ||
  hold? ||
  (remove? && removed?) ||
  (purge? && purged?))
    end

    def deb_fp(type, op, *pat)
      raise Debian::Error, 'no filename associated' unless @filename || @artab
      @artab.open(type) do |ctz|
        Debian::Utils.gunzip(ctz) do |ct|
          Debian::Utils.tar(ct, op, *pat) do |fp|
            if block_given?
              ct.close
              retval = yield(fp)
              fp.close
              return retval
            else
              ct.close
              return fp
            end
          end
        end
      end
    end

    def control_fp(op, *pat)
      deb_fp('control.tar.gz', op, *pat) do |fp|
        if block_given?
          yield(fp)
        else
          fp
        end
      end
    end

    def data_fp(op, *pat)
      deb_fp('data.tar.gz', op, *pat) do |fp|
        if block_given?
          yield(fp)
        else
          fp
        end
      end
    end

    def filename=(fn)
      @filename = fn
      @artab = Debian::Ar.new(fn)
      control_fp(Debian::Utils::TAR_LIST) do |fp|
        fp.each do |line|
          line.chomp!
          line.gsub!(/^\.\//, '')
          @control.push(line) unless line.empty?
        end
      end
      data_fp(Debian::Utils::TAR_LIST) do |fp|
        fp.each do |line|
          @data.push(line.chomp)
        end
      end
      @artab.close
      freeze
    end

    attr_writer :control

    attr_writer :data

    def controlFile(cfile = 'control')
      unless @control.find { |c| c == cfile }
        raise Debian::Error, "no such cfile #{cfile}"
      end
      control_fp(Debian::Utils::TAR_EXTRACT, "*/#{cfile}") do |fp|
        if block_given?
          yield(fp)
        else
          fp
        end
      end
    end

    def controlData(cfile = 'control')
      controlFile(cfile) { |fp| fp.readlines.join('') }
    end

    def dataFile(fname)
      if /^\.\// =~ fname
        pat = fname
      else
        fname.gsub!(/^\//, '')
        pat = "*/#{fname}"
      end
      data_fp(Debian::Utils::TAR_EXTRACT, pat) do |fp|
        if block_given?
          yield(fp)
        else
          fp
        end
      end
    end

    def dataData(fname)
      dataFile(fname) { |fp| fp.readlines.join('') }
    end

    def sys_tarfile
      raise Debian::Error, 'no filename associated' unless @filename || @artab
      @artab.open('data.tar.gz') do |dtz|
        Debian::Utils.gunzip(dtz) do |dt|
          if block_given?
            yield(dt)
          else
            dt
          end
        end
      end
    end

    def unmet(packages, rels = [])
      us = []
      update_deps
      # puts "N: #{self} unmet d:#{@deps['Depends']} r:#{@deps['Recommends']} s:#{@deps['Suggests']}"
      if rels.empty?
        rels = ['Pre-depends', 'Depends', 'Recommends', 'Suggests', 'Enhances']
      end
      rels.each do |rel|
        rel.capitalize!
        @deps[rel] && @deps[rel].each do |dep|
          # puts "N: #{self} unmet? #{dep}"
          us += dep.unmet(packages).collect do |ua|
            ua.each do |u|
              u.package = self
              u.relation = rel
            end
          end
        end
      end
      us
    end
  end

  ################################################################
  class Dsc
    include Field
    @@reqfields = %w(binary
                     version maintainer
                     architecture files).collect(&:capitalize)
    @@dependency = ['build-depends', 'build-depends-indep',
                    'build-conflicts', 'build-conflicts-indep'].collect(&:capitalize)

    # XXX: build-dependecy as Deb dependency
    # Files infomation
    def initialize(info_s, fields = [])
      parse_fields(info_s, @@reqfields, fields)
      # in Sources file, Package: is used
      # in *.dsc file, Source: is used
      if @info['Package']
        @package = @info['Package']
        @source = @info['Package']
      end
      if @info['Source']
        @package = @info['Source']
        @source = @info['Source']
      end
      @binary = @info['Binary'].split(',').each(&:strip!)
      @deps = {}
    end
    attr_reader :package, :source, :binary, :version
    def update_deps
      @@dependency.each do |depf|
        next unless @info[depf]
        @deps[depf] = {}
        @info[depf].split(',') do |deps|
          @deps[depf].push(Dep.new(deps))
        end
      end
    end
    private :update_deps
  end

  ################################################################
  class ArchivesError < Error; end
  class Archives
    def self.parseAptLine(_src)
      # XXX: support apt line?
      # deb file://<path> <distro> [<component> ...]
      # =>  <path>/dists/<distro>/<component>/binary-${ARCH}/Packages
      # deb-src file://<path> <distro> [<component> ...]
      # =>  <path>/dists/<distro>/<component>/source/Sources.gz
      raise NotImplementedError
    end

    def self.load(filename, *arg)
      case File.basename(filename)
      when /Source(.gz)?/ then Sources.new(filename, *arg)
      else Packages.new(filename, *arg)
      end
    end

    def self.parseArchiveFile(file, &block)
      return {} if file == ''
      f = if /\.gz$/ =~ file
            IO.popen("gunzip < #{file}")
          else
            File.open(file)
          end
      l = Archives.parse(f, &block)
      f.close
      l
    end

    def self.parse(f)
      l = {}
      f.each("\n\n") do |info|
        d = yield info
        next unless d
        next if l[d.package] && d < l[d.package]
        l[d.package] = d
      end
      l
    end

    def initialized
      @file = []
      @lists = {}
    end
    attr_reader :file, :lists
    def to_s
      @file.join('+')
    end

    def add(da)
      # XXX: self destructive!
      return unless da
      @file += da.file
      @file.compact!
      da.each do |pkg, d1|
        self[pkg] = d1
      end
      self
    end

    def +(da)
      if self.class != da.class
        raise Debian::ArchiveError,
              "E: `+' type mismatch #{self.class} != #{da.class}"
      end
      nda = self.class.new
      nda.add(self)
      nda.add(da)
      nda
    end

    def sub(da)
      # XXX: self destructive!
      return unless da
      @file -= da.file
      da.each_key do |package|
        @lists.delete(package)
      end
      self
    end

    def -(da)
      if self.class != da.class
        raise Debian::ArchiveError,
              "E: `-' type mismatch #{self.class} != #{da.class}"
      end
      nda = self.class.new
      nda.add(self) # copy
      nda.sub(da)
      nda
    end

    def intersect(da1, da2)
      # XXX: self destructive!
      return unless da2
      @file += ["#{da1.file}&#{da2.file}"]
      @file.compact!
      da1.each_key do |package|
        next unless da2[package]
        d = da1[package]
        d = da2[package] if da1[package] < da2[package]
        @lists[package] = d
      end
      self
    end

    def &(da)
      if self.class != da.class
        raise Debian::ArchiveError,
              "E: `-' type mismatch #{self.class} != #{da.class}"
      end
      nda = self.class.new
      nda.intersect(self, da)
      nda
    end

    def <<(deb)
      nda = self.class.new
      nda.add(self)
      return nda unless deb
      nda[deb.package] = deb
      nda
    end

    def []=(package, deb)
      # XXX: self destructive!
      if d0 = @lists[package]
        if d0 < deb
          @lists[package] = deb	# update new one
        else
          d0	# original is the latest version
        end
      else
        @lists[package] = deb	# not found, add new one
      end
    end

    def store(package, deb)
      self[package] = deb
    end

    def >>(deb)
      nda = self.class.new
      nda.add(self)
      return nda unless deb
      nda.delete_if { |_pkg, d| d == deb }
      nda
    end

    def delete(package)
      @lists.delete(package)
    end

    def delete_if(&block)
      @lists.delete_if(&block)
    end

    def each
      @lists.each do |package, deb|
        yield(package, deb)
      end
    end

    def each_key
      @lists.each_key do |package|
        yield(package)
      end
    end

    def each_value
      @lists.each_value do |deb|
        yield(deb)
      end
    end

    def packages
      if block_given?
        each_value do |p|
          yield p
        end
      else
        @lists.values
      end
    end

    def pkgnames
      if block_given?
        each_key do |p|
          yield p
        end
      else
        @lists.keys
      end
    end

    def each_package(&block)
      each_value(&block)
    end

    def empty?
      @lists.empty?
    end

    def has_key?(pkg)
      @lists.key?(pkg)
    end

    def has_value?(deb)
      @lists.value?(deb)
    end

    def include?(key)
      key?(key)
    end

    def indexes(*arg)
      @lists.values_at(*arg)
    end

    def indices(*arg)
      @lists.indices(*arg)
    end

    def key?(pkg)
      key?(pkg)
    end

    def keys
      @lists.keys
    end

    def value?(deb)
      value?(deb)
    end

    def values
      @lists.values
    end

    def length
      @lists.length
    end

    def [](package)
      @lists[package]
    end

    def package(package)
      @lists[package]
    end
  end

  ################################################################
  class Sources < Archives
    def initialize(file = '', pkgs = [], fields = [])
      @lists = Archives.parseArchiveFile(file) do |info|
        info =~ /(?:Package|Source):\s(.*)$/
        if pkgs.empty? || pkgs.include?(Regexp.last_match(1))
          d = Dsc.new(info, fields)
          yield d if block_given?
          d.freeze
        end
      end
    end
  end

  ################################################################
  class Packages < Archives
    def initialize(file = '', pkgs = [], fields = [])
      @provides = {}
      @file = [file]
      @lists = Archives.parseArchiveFile(file) do |info|
        info =~ /Package:\s(.*)$/
        if pkgs.empty? || pkgs.include?(Regexp.last_match(1))
          d = Deb.new(info, fields)
          add_provides(d)
          yield d if block_given?
          d.freeze
        end
      end
    end

    def add_provides(deb)
      @provides[deb.package] = [] unless @provides[deb.package]
      unless @provides[deb.package].include?(deb)
        @provides[deb.package].push(deb)
      end

      if deb.provides
        deb.provides.each do |p|
          @provides[p] = [] unless @provides[p]
          @provides[p].push(deb) unless @provides[p].include?(deb)
        end
      end
      deb
    end

    def del_provides(deb)
      return unless deb
      deb.provides.each do |p|
        @provides[p].delete(deb)
      end
    end
    private :add_provides, :del_provides

    def provides(pkg = '')
      if pkg != ''
        return @provides[pkg]
      else
        return @provides
      end
    end

    # overrides, provides management
    def add(p)
      # XXX: self destructive!
      super(p)
      p.provides.each do |pkg, debs|
        @provides[pkg] = [] unless @provides[pkg]
        @provides[pkg] += debs
        @provides[pkg].uniq!
      end
      self
    end

    def +(p)
      np = self.class.new
      np.add(self)
      np.add(p)
      np
    end

    def sub(p)
      # XXX: self destructive!
      super(p)
      p.provides.each do |pkg, debs|
        @provides[pkg] -= debs if @provides[pkg]
      end
      self
    end

    def -(p)
      np = self.class.new
      np.add(self)
      np.sub(p)
      np
    end

    def intersect(p1, p2)
      # XXX: self destructive!
      super(p1, p2)
      @lists.each_value do |deb|
        add_provides(deb)
      end
      self
    end

    def &(p)
      np = self.class.new
      np.intersect(self, p)
      np
    end

    def <<(deb)
      np = self.class.new
      np.add(self)
      np[deb.package] = deb if deb
      np
    end

    def []=(package, deb)
      # XXX: self destructive!
      d = super(package, deb)
      add_provides(d)
      d
    end

    def >>(deb)
      np = self.class.new
      np.add(self)
      np.delete(deb.package) if np.value?(deb)
      np
    end

    def delete(package)
      deb = super(package)
      del_provides(deb)
    end
  end

  ################################################################
  class Status < Packages
    def initialize(pkgs = [], fields = [])
      super(Dpkg::STATUS_FILE, pkgs, fields) do |d|
        if d.status == 'installed'
          c = ['control']
          re = Regexp.new(Regexp.escape(File.join(Dpkg::PACKAGE_INFO_DIR,
                                                  "#{d.package}.")))
          Dir[File.join(Dpkg::PACKAGE_INFO_DIR, "#{d.package}.*")].each do |fn|
            case File.basename(fn)
            when "#{d.package}.list" then
              d.data = IO.readlines(fn).collect(&:chomp)
            else
              c.push(fn.gsub(re, ''))
            end
          end
          d.control = c
        end
        yield d if block_given?
        d
      end
    end
  end
end
