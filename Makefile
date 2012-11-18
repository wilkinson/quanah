#-  GNU Makefile

#-  Makefile ~~
#
#   This contains live instructions for development on the Quanah library.
#
#                                                       ~~ (c) SRW, 17 Nov 2012

PROJECT_ROOT    :=  $(realpath $(dir $(firstword $(MAKEFILE_LIST))))

include $(PROJECT_ROOT)/tools/macros.make

NPM     :=  $(call contingent, npm)
RM      :=  $(call contingent, grm rm) -rf

.PHONY: all clean clobber distclean reset run
.SILENT: ;

'': help;

all: run

clean: reset

clobber: clean

distclean: clobber
	@   $(RM) $(addprefix $(PROJECT_ROOT)/, \
                .d8_history .v8_history ./node_modules/ npm-debug.log *.tgz)

help:
	@   $(call show-usage-info)

reset:
	@   $(call contingent, clear)

run: test

###

.PHONY: test

test: $(PROJECT_ROOT)/node_modules/
	@   $(NPM) test

###

$(PROJECT_ROOT)/node_modules/: $(PROJECT_ROOT)/package.json
	@   $(NPM) install

###

#-  NOTE: The following rule is still experimental and should not be used in
#   production, especially if you are planning to convert the resulting output
#   back into JavaScript again for deployment. Such files might pass the unit
#   tests but still contain bugs and/or security vulnerabilities.

%.coffee: %.js
	@   $(call contingent, js2coffee) $< > $@

###

%:
	@   $(call alert, 'No target "$@" found.')

#-  vim:set syntax=make:
