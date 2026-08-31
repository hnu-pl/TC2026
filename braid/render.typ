#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *

#import "util.typ": sum, count-lines, get-extension, join-lines

#let build-render-api(state) = {
  let lang-infos = state.lang-infos
  let lang-aliases = state.lang-aliases
  let files = state.files-db
  let build-dir = state.build-dir

  let codly-local = state.codly-local

  let code-languages = lang-infos.pairs().fold(codly-languages, (acc, kv) => {
    let lang = kv.at(0)
    let info = kv.at(1)
    if info.codly-lang == none {
      acc
    } else {
      (..acc, (lang): info.codly-lang)
    }
  })

  let read-raw(path, lang: none, block: true, preprocess: none) = {
    let filename = path.split("/").last()
    let matches = files.filter(it => it.file == filename)
    if matches.len() > 0 {
      let content = matches.at(0).content
      if preprocess != none {
        preprocess(content)
      } else {
        raw(content, lang: lang, block: block)
      }
    } else {
      box(
        fill: rgb("#fff1f1"),
        stroke: 0.5pt + rgb("#e5b3b3"),
        radius: 3pt,
        inset: 5pt,
        [Cannot read #raw(path, block: false) (maybe non-existent)],
      )
    }
  }

  // helper function for code to extract the raw code block from the body
  let extract-rawcode(body) = {
    if body == none {
      panic("Error: 'body' is a required parameter.")
    }

    if body.has("children") {
      let rs = body.at("children").filter(it => it.func() == raw)
      if rs.len() != 1 {
        panic("Error: 'body' must contain exactly one raw code block. Current body: " + repr(body))
      }
      rs.at(0)
    } else if body.func() == raw {
      body
    } else {
      panic("Error: 'body' must be a raw code block or a sequence containing exactly one raw code block. Current body: " + repr(body))
    }
  }

  // helper function for code to resolve the file name if not provided (when file is none)
  let resolve-code-file(file, rawcode) = {
    if file != none {
      return file
    }

    // generate file name based on the top level heading and the language of the code block
    let headings = query(selector(heading).before(here()))
    let number = if headings.len() > 0 {
      let nums = counter(heading).at(headings.last().location())
      ("00" + str(nums.at(0))).slice(-3)
    } else {
      "000"
    }

    "Sec" + number + "." + get-extension(lang-infos, rawcode.lang)
  }

  let resolve-offset(code-file, rawcode) = {
    let past-snips = query(selector(<meta:code-snippet>).before(here()))
    let my-snips = past-snips.filter(it => it.value.at("file") == code-file)
    let nth0 = my-snips.len()
    let my-offset = sum(my-snips.map(it => count-lines(it.value.at("code")))) + my-snips.len() * join-lines(lang-infos, rawcode.lang).len()

    (nth0: nth0, offset: my-offset)
  }

  let render-aux-output(rawcode, code-file, nth0, lang-info, output-render) = {
    if "interactive" in lang-info {
      let outfile = code-file + "-output." + ("0" + str(nth0)).slice(-2)
      // per-call override takes precedence over the language config's default
      let effective-output-render = if output-render != none { output-render } else { lang-info.at("output-render", default: none) }
      no-codly(read-raw(build-dir + "/" + outfile, block: true, preprocess: effective-output-render))
    }
    if nth0 == 0 and "compile" in lang-info and lang-info.compile != none {
      let compilefile = code-file + "-compile"
      no-codly(read-raw(build-dir + "/" + compilefile, block: true))
    }
  }

  let resolve-orig-icon(rawcode-lang, code-languages, lang-aliases) = {
    let orig-lang = if rawcode-lang in lang-aliases.keys() {
      lang-aliases.at(rawcode-lang)
    } else {
      rawcode-lang
    }

    if orig-lang in code-languages {
      code-languages.at(orig-lang).icon
    } else {
      panic("Error: 'orig-lang' must be a recognized code language. Current orig-lang: " + repr(orig-lang))
    }
  }

  let code(file: none, visible: true, output-render: none, body) = {
    let rawcode = extract-rawcode(body)

    context {
      let code-file = resolve-code-file(file, rawcode)
      let offset-info = resolve-offset(code-file, rawcode)
      let nth0 = offset-info.nth0 // nth code snippet for this file (0-based)
      let my-offset = offset-info.offset // line number offset for this snippet
      let lang-info = lang-infos.at(rawcode.lang)
      let orig-icon = resolve-orig-icon(rawcode.lang, code-languages, lang-aliases)

      [
        #codly(offset: my-offset)
        #local(
          ..codly-local,
          languages: ((rawcode.lang): (name: stack(dir: ltr, spacing: 0.1em, orig-icon, [*#code-file*]), icon: none)),
        )[ #rawcode ]
        #metadata((file: code-file, lang: rawcode.lang, code: rawcode.text)) <meta:code-snippet>
      ]

      render-aux-output(rawcode, code-file, nth0, lang-info, output-render)
    }
  }

  (
    code: code,
    read-raw: read-raw,
    code-languages: code-languages,
  )
}
