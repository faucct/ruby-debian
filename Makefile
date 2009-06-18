#
# Makefile
#
SHELL = /bin/sh
RUBY = ruby
RM = rm
#### Start of system configuration section. ####
prefix = $(DESTDIR)/usr
bindir = $(prefix)/bin
libdir = $(prefix)/lib/ruby/$(shell $(RUBY) -rrbconfig -e 'puts Config::CONFIG["ruby_version"]')
mandir = $(DESTDIR)/usr/share/man
bins = $(wildcard bin/*)
libs = $(wildcard lib/*.rb)
libs_debian = $(wildcard lib/debian/*.rb)
man1 = $(wildcard man/*.1)

all:
clean:
	@-(cd t; rm -f test.log)
distclean:	clean
realclean:	distclean

install:
	@$(RUBY) -r ftools -e 'File::makedirs(*ARGV)' $(bindir)
	@$(RUBY) -r ftools -e 'File::makedirs(*ARGV)' $(libdir)
	@for b in $(bins); do \
	 $(RUBY) -r ftools -e 'File::install(ARGV[0], ARGV[1], 0755, true)' \
		$$b $(bindir); \
	done
	@for rb in $(libs); do \
	 $(RUBY) -r ftools -e 'File::install(ARGV[0], ARGV[1], 0644, true)'\
		 $$rb $(libdir); \
	done
	@mkdir $(libdir)/debian/
	@for rb in $(libs_debian); do \
	 $(RUBY) -r ftools -e 'File::install(ARGV[0], ARGV[1], 0644, true)'\
		 $$rb $(libdir)/debian; \
	done
	@mkdir -p $(mandir)/man1
	@for m in $(man1); do \
	 $(RUBY) -r ftools -e 'File::install(ARGV[0], ARGV[1], 0644, true)' \
		$$m $(mandir)/man1; \
	done

test:
	@(cd t; $(RUBY) testall.rb -o test.log)
