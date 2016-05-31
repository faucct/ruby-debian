require 'mkmf'

$LDFLAGS << ' -lapt-pkg'

dir_config('debian_version')

create_makefile('debian_version')
