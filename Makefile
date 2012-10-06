#-  GNU Makefile

#-  Makefile ~~
#
#   This contains live instructions for development on the Quanah library.
#
#                                                       ~~ (c) SRW, 05 Oct 2012

PROJECT_ROOT    :=  $(realpath $(dir $(firstword $(MAKEFILE_LIST))))

include $(PROJECT_ROOT)/tools/macros.make

ENGINES :=  js jsc v8 d8 v8cgi node nodejs narwhal-jsc rhino ringo narwhal  \
                couchjs phantomjs # avmshell
JS      :=  $(strip $(call contingent, $(ENGINES)))
JSLIBS  :=  libs.js
QUANAH  :=  src/quanah.js
SRCJS   :=  $(JSLIBS) $(QUANAH) tools/chubby-checker.js $(wildcard tests/*.js)
EXEJS   :=  main.js
MINJS   :=  $(EXEJS:%.js=%-min.js)
HTML    :=  index.html

CAT     :=  $(call contingent, gcat cat)
CLOSURE :=  $(call contingent, closure-compiler closure)
CP      :=  $(call contingent, rsync gcp cp)
CURL    :=  $(call contingent, curl) #-sS
OPEN    :=  $(call contingent, x-www-browser gnome-open open)
RM      :=  $(call contingent, grm rm) -rf
TIME    :=  $(call contingent, time)
TOUCH   :=  $(call contingent, gtouch touch)
WEBPAGE :=  $(call contingent, ruby jruby) ./tools/webpage.rb
YUICOMP :=  $(call contingent, yui-compressor yuicompressor)

define compile-with-google-closure
    $(CLOSURE) --compilation_level SIMPLE_OPTIMIZATIONS \
        $(1:%=--js %) --js_output_file $(2)
endef

define compile-with-yuicompressor
    JS_TEMP_FILE="$(strip $(call random-prefix, $(2)))"                 ;   \
    $(CAT) $(1) > $${JS_TEMP_FILE}                                      ;   \
    $(YUICOMP) --type js $${JS_TEMP_FILE} -o $(2)                       ;   \
    $(RM) $${JS_TEMP_FILE}
endef

define compile-js
    $(call aside, "Optimizing scripts: $(1) --> $(2)")                  ;   \
    $(call compile-with-yuicompressor, $(1), $(2))
endef

define fetch-url
    $(call hilite, 'Fetching "$(strip $(2))" ...')                      ;   \
    $(CURL) -o $(2) $(1)
endef

define random-prefix
    $${RANDOM:=`hexdump -n 2 -e '/2 "%u"' /dev/urandom`}-$(strip $(1))
endef

.PHONY: all clean clobber distclean reset run
.INTERMEDIATE: json2.js
.SILENT: ;

all: run

clean: reset
	@   $(RM) $(EXEJS) results1.out results2.out time-data.out

clobber: clean
	@   $(RM) $(abspath $(filter-out $(SRCJS), $(wildcard *.js)))

distclean: clobber
	@   $(RM) .d8_history .v8_history $(HTML) libs.js npm-debug.log *.tgz

reset:
	@   $(call contingent, clear)

run: quick

###

.PHONY: benchmark browse browser check check-jasmine check-old quick test

benchmark: $(EXEJS)
	@   $(RM) time-data.out                                         ;   \
            for each in $(call available, $(ENGINES)); do                   \
                $(call aside, "$${each}")                               ;   \
                for i in 1 2 3; do                                          \
                    echo $${each} >>time-data.out 2>&1                  ;   \
                    ($(TIME) $${each} $(EXEJS) >/dev/null 2>&1)             \
                                                >>time-data.out 2>&1    ;   \
                done                                                    ;   \
            done                                                        ;   \
            $(call hilite, '(analysis placeholder)')

browse: browser
	@   if [ -f $(HTML) ]; then $(OPEN) $(HTML); fi

browser: $(EXEJS) $(HTML)

check: check-old check-jasmine

check-jasmine: $(QUANAH)
	@   if [ -f test/test.html ]; then $(OPEN) test/test.html; fi

check-old: $(EXEJS)
	@   $(RM) results1.out results2.out                             ;   \
            for each in $(call available, $(ENGINES)); do                   \
                $(call aside, "$${each}")                               ;   \
                if [ ! -f results1.out ]; then                              \
                    $${each} $(EXEJS) 2>&1 >results1.out                ;   \
                    if [ $$? -eq 0 ]; then                                  \
                        $(call hilite, 'Success.')                      ;   \
                    else                                                    \
                        $(call alert, 'Failure (execution).')           ;   \
                    fi                                                  ;   \
                    sort results1.out -o results1.out                   ;   \
                else                                                        \
                    $${each} $(EXEJS) 2>&1 >results2.out                ;   \
                    if [ $$? -eq 0 ]; then                                  \
                        sort results2.out -o results2.out               ;   \
                        diff results1.out results2.out 2>&1 >/dev/null  ;   \
                        if [ $$? -eq 0 ]; then                              \
                            $(call hilite, 'Success.')                  ;   \
                        else                                                \
                            $(call alert, 'Failure (different output).');   \
                        fi                                              ;   \
                    else                                                    \
                        $(call alert, 'Failure (execution).')           ;   \
                    fi                                                  ;   \
                fi                                                      ;   \
            done

fast: $(EXEJS)
	@   QUICK_JS_FILE="$(strip $(call random-prefix, $(EXEJS)))"    ;   \
            $(call compile-js, $(EXEJS), $${QUICK_JS_FILE})             ;   \
            $(call aside, "$(JS) $${QUICK_JS_FILE}")                    ;   \
            $(TIME) $(JS) $${QUICK_JS_FILE}                             ;   \
            if [ $$? -eq 0 ]; then                                          \
                $(call hilite, 'Success.')                              ;   \
            else                                                            \
                $(call alert, 'Failure.')                               ;   \
            fi                                                          ;   \
            $(RM) $${QUICK_JS_FILE}

faster: $(MINJS)
	@   $(call aside, "$(JS) $<")                                   ;   \
            $(TIME) $(JS) $<                                            ;   \
            if [ $$? -eq 0 ]; then                                          \
                $(call hilite, 'Success.')                              ;   \
            else                                                            \
                $(call alert, 'Failure.')                               ;   \
            fi

quick:
	@   QUICK_JS_FILE="$(strip $(call random-prefix, $(EXEJS)))"    ;   \
            $(CAT) $(filter-out $(JSLIBS), $(SRCJS)) > $${QUICK_JS_FILE};   \
            $(call aside, "$(JS)")                                      ;   \
            $(TIME) $(JS) $${QUICK_JS_FILE}                             ;   \
            if [ $$? -eq 0 ]; then                                          \
                $(call hilite, 'Success.')                              ;   \
            else                                                            \
                $(call alert, 'Failure.')                               ;   \
            fi                                                          ;   \
            $(RM) $${QUICK_JS_FILE}

test: check

###

$(EXEJS): $(SRCJS)
	@   $(CAT) $^ > $@

$(HTML): | $(EXEJS)
	@   $(WEBPAGE) -o $@ $(EXEJS)

$(JSLIBS): json2.js
	@   $(CAT) $^ > $@

$(MINJS): $(EXEJS)
	@   $(call compile-js, $<, $@)

###

#-  NOTE: I cache a few JavaScript frameworks and libraries in a directory on
#   my personal machine, and I highly recommend it for rapid development. If
#   you don't have the same personal settings, though, these directions will
#   still fall back to our trusty friend 'curl' :-)

json2.js:
	@   CROCKHUB="https://raw.github.com/douglascrockford"          ;   \
            if [ -f $(CODEBANK)/lib/JavaScript/json2.js ]; then             \
                $(CP) $(CODEBANK)/lib/JavaScript/json2.js $@            ;   \
            else                                                            \
                $(CURL) -o $@ $${CROCKHUB}/JSON-js/master/json2.js      ;   \
            fi 

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
