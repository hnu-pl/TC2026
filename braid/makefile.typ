#import "util.typ": snippet-break-str

#let build-makefile-api(state) = {
  let lang-infos = state.lang-infos
  let typfile-path = state.typfile-path
  let tag-stdioe-cmd = state.tag-stdioe-cmd

  let make-header-lines() = (
    ".PHONY: all clean",
    "",
  )

  let make-variable-lines(srcs, outs, inps, comps, compile-stamp) = (
    "SRCS_ALL = " + srcs.join(" "),
    "OUTS_ALL = " + outs.join(" "),
    "INPS_ALL = " + inps.join(" "),
    "COMPILES_ALL = " + comps.join(" "),
    "COMPILE_STAMP = " + compile-stamp,
    "DIRTY_SRCS ?=",
    "SRCS = $(if $(strip $(DIRTY_SRCS)),$(DIRTY_SRCS),$(SRCS_ALL))",
    "OUTS = $(if $(strip $(DIRTY_SRCS)),$(foreach o,$(OUTS_ALL),$(if $(filter $(patsubst %-output,%,$(o)),$(SRCS)),$(o))),$(OUTS_ALL))",
    "INPS = $(if $(strip $(DIRTY_SRCS)),$(foreach o,$(INPS_ALL),$(if $(filter $(patsubst %-input,%,$(o)),$(SRCS)),$(o))),$(INPS_ALL))",
    "COMPILES = $(if $(strip $(DIRTY_SRCS)),$(foreach o,$(COMPILES_ALL),$(if $(filter $(patsubst %-compile,%,$(o)),$(SRCS)),$(o))),$(COMPILES_ALL))",
    "",
  )

  let make-config-lines() = (
    "TYPFILE = " + typfile-path,
    "TAGSTDIOE = " + tag-stdioe-cmd,
    "SNIPPET_BREAK = " + snippet-break-str,
    "",
  )

  let make-define-lines() = (
    "define typst_codefile",
    "\ttypst eval \"query(<meta:code-file>).filter(it => it.value.file == \\\"$(1)\\\")\" --in $(TYPFILE) | jq -r '.[].value.code' > \"$(1)\"",
    "endef",
    "",
    "define split_snippet_output",
    "\trm -f \"$(1).*\"",
    "\t: > \"$(1).00\"",
    "\tawk -v base=\"$(1)\" -v marker=\"$(SNIPPET_BREAK)\" '\\",
    "\tBEGIN { i = 0; out = sprintf(\"%s.%02d\", base, i) }\\",
    "\tindex($$0, marker) > 0 { i++; out = sprintf(\"%s.%02d\", base, i); print \"\" > out; close(out); next }\\",
    "\t{ print > out }\\",
    "\t' \"$(1)\"",
    "endef",
    "",
  )

  let make-core-rule-lines() = (
    "all: $(SRCS) $(COMPILE_STAMP) $(OUTS)",
    "",
    "$(COMPILE_STAMP): $(COMPILES)",
    "\t@touch $@",
    "",
    "clean:",
    "\trm -f $(SRCS) $(OUTS) $(INPS) $(COMPILES) $(COMPILE_STAMP) $(addsuffix .*, $(OUTS))",
    "",
  )

  let make-src-rule-lines(srcs) = srcs.map(srcfile => (
    srcfile + ": $(TYPFILE)",
    "\t$(call typst_codefile,$@)",
  )).join()

  let make-interactive-rule-lines(lang-infos) = lang-infos.filter(it => "interactive" in it).pairs().map(it => {
    let info = it.at(1)
    let repl = info.interactive
    (
      "",
      "%." + info.ext + "-output:" + " %." + info.ext + " %." + info.ext + "-input | $(COMPILE_STAMP)",
      "\tcat $(word 2, $^) | $(TAGSTDIOE) \"" + repl("$<") + "\" > $@",
      "\t$(call split_snippet_output,$@)",
      "",
      "%." + info.ext + "-input:",
      "\t@if [ ! -e $@ ]; then : > $@; fi",
    )
  }).join()

  let make-compile-rule-lines(lang-infos) = lang-infos.filter(it => "compile" in it and it.compile != none).pairs().map(it => {
    let info = it.at(1)
    let compile = info.compile
    (
      "",
      "%." + info.ext + "-compile:" + " %." + info.ext,
      "\t@tmp=\"$@.tmp\"; rm -f \"$$tmp\"; if " + compile("$<") + " > \"$$tmp\" 2>&1; then \\",
      "\t  { echo \"COMPILE SUCCESS: $<\"; cat \"$$tmp\"; } > \"$@\"; \\",
      "\telse \\",
      "\t  status=$$?; { echo \"COMPILE FAILURE: $<\"; cat \"$$tmp\"; } > \"$@\"; rm -f \"$$tmp\"; exit $$status; \\",
      "\tfi; rm -f \"$$tmp\"",
    )
  }).join()

  let makefile() = {
    let filemetas = query(<meta:code-file>)
    let intermetas = filemetas.filter(it => "interactive" in lang-infos.at(it.value.lang))
    let compilemetas = filemetas.filter(it => {
      let info = lang-infos.at(it.value.lang)
      "compile" in info and info.compile != none
    })
    let srcs = filemetas.map(it => it.value.file)
    let outs = intermetas.map(it => it.value.file + "-output")
    let inps = intermetas.map(it => it.value.file + "-input")
    let comps = compilemetas.map(it => it.value.file + "-compile")
    let compile-stamp = ".compile.stamp"

    let lines = (
      make-header-lines()
      + make-variable-lines(srcs, outs, inps, comps, compile-stamp)
      + make-config-lines()
      + make-define-lines()
      + make-core-rule-lines()
      + make-src-rule-lines(srcs)
      + make-interactive-rule-lines(lang-infos)
      + make-compile-rule-lines(lang-infos)
    )

    [
      #metadata((file: "Makefile", lang: "makefile", code: lines.join("\n"))) <meta:make-file>
    ]
  }

  (makefile: makefile)
}
