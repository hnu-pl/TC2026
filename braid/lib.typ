#import "config.typ": build-config
#import "render.typ": build-render-api
#import "makefile.typ": build-makefile-api
#import "filesdb.typ": build-files-db-api
#import "util.typ": get-extension, join-lines, join-str, count-lines, snippet-break-str, colorize-stdioe-output

#let setup(config: (:)) = {
  let cfg-state = build-config(config: config)
  let render-api = build-render-api(cfg-state)
  let makefile-api = build-makefile-api(cfg-state)
  let filesdb-api = build-files-db-api(cfg-state)

  ( // most users may only need `init` and `code` after setup
    init: () => {
      context { (filesdb-api.emit-code-file-meta)() }
      context { (filesdb-api.emit-dirty-file-meta)() }
      context { (makefile-api.makefile)() }
    },
    code: render-api.code,
    code-languages: render-api.code-languages, // rendering information from build-config added to the default codly language setting
    read-raw: render-api.read-raw, // utility function to read text and display as raw block from the files registered in filesdb, with fallback error messages for missing files

    // re-export of build-config result, in case one needs to debug config setup
    cfg-state: cfg-state,

    // re-export of util, some with configs partially applied
    get-extension: lang => get-extension(cfg-state.lang-infos, lang),
    join-lines: lang => join-lines(cfg-state.lang-infos, lang),
    join-str: lang => join-str(cfg-state.lang-infos, lang),
    count-lines: count-lines,
    snippet-break-str: snippet-break-str,
    colorize-stdioe-output: colorize-stdioe-output, // example output-render fn: colorizes I:/E:/O: tagged lines
  )
}
