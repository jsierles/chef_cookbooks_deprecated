#                                          -*- ruby -*-
# extconf.rb
#
# Modified at: <1999/8/19 06:38:55 by ttate> 
#

require 'mkmf'

$CFLAGS = ""
$LDFLAGS = "-lshadow"

if( ! (ok = have_library("shadow","getspent")) )
  $LDFLAGS = ""
  ok = have_func("getspent")
end

ok &= have_func("sgetspent")
ok &= have_func("fgetspent")
ok &= have_func("setspent")
ok &= have_func("endspent")
ok &= have_func("lckpwdf")
ok &= have_func("ulckpwdf")

if ok
  create_makefile("shadow")
end
