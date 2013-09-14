NODE?=node
NPM?=npm
BROWSERIFY?=node_modules/browserify/bin/cmd.js
MOCHA?=node_modules/mocha/bin/mocha
MOCHA_OPTS?=
JS_COMPILER=node_modules/uglify-js/bin/uglifyjs
JS_COMPILER_OPTS?=--no-seqs

MODULE=dagre

# There does not appear to be an easy way to define recursive expansion, so
# we do our own expansion a few levels deep.
JS_SRC:=$(wildcard lib/*.js lib/*/*.js lib/*/*/*.js)
JS_TEST:=$(wildcard test/*.js test/*/*.js test/*/*/*.js)

DEMO_SRC=$(wildcard demo/*)
DEMO_OUT=$(addprefix out/dist/, $(DEMO_SRC))

BENCH_FILES?=$(wildcard bench/graphs/*)

OUT_DIRS=out out/dist out/dist/demo

.PHONY: all release dist dist_demo test clean fullclean

all: dist test

release: all
	src/release/release.sh $(MODULE) out/dist

dist: out/dist/$(MODULE).js out/dist/$(MODULE).min.js dist_demo

dist_demo: out/dist/demo $(DEMO_OUT)

test: out/dist/$(MODULE).js $(JS_TEST) $(JS_SRC)
	$(NODE) $(MOCHA) $(MOCHA_OPTS) $(JS_TEST)

bench: bench/bench.js $(MODULE_JS)
	@$(NODE) bench/bench.js $(BENCH_FILES)

clean:
	rm -f lib/version.js
	rm -rf out

fullclean: clean
	rm -rf node_modules

$(OUT_DIRS):
	mkdir -p $@

out/dist/$(MODULE).js: browser.js Makefile out/dist node_modules lib/version.js $(JS_SRC)
	$(NODE) $(BROWSERIFY) $< > $@

out/dist/$(MODULE).min.js: out/dist/$(MODULE).js
	$(NODE) $(JS_COMPILER) $(JS_COMPILER_OPTS) $< > $@

out/dist/demo/%: demo/%
	@sed 's|../dist/dagre.min.js|../dagre.min.js|' < $< > $@

lib/version.js: src/version.js package.json
	$(NODE) src/version.js > $@

node_modules: package.json
	$(NPM) install
