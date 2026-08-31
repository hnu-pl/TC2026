#import "@preview/digestify:0.2.0": sha256, bytes-to-hex
#import "util.typ": group-by, join-str

#let build-files-db-api(state) = {
  let files = state.files-db
  let lang-infos = state.lang-infos

  let emit-code-file-meta() = {
    let snippet-group = group-by(
      query(<meta:code-snippet>).map(it => it.value),
      it => it.at("file")
    ).values()

    let file-dicts = snippet-group.map(ds => {
      let new-dict = ds.at(0)
      let lang = new-dict.at("lang")
      new-dict.insert("code", ds.map(d => d.code).join(join-str(lang-infos, lang)))
      new-dict.insert("size", new-dict.code.len() + 1)
      new-dict.insert("sha256", bytes-to-hex(sha256(bytes(new-dict.code + "\n"))))
      new-dict
    })

    for d in file-dicts {
      [#metadata(d) <meta:code-file>]
    }
  }

  let emit-dirty-file-meta() = {
    let filemetas = query(<meta:code-file>).map(it => it.value)
    let dirty-srcs = filemetas.filter(meta => {
      let matches = files.filter(it => it.file == meta.file)
      if matches.len() == 0 {
        true
      } else {
        let old = matches.at(0)
        old.size != meta.size or old.sha256 != meta.sha256
      }
    })

    for d in dirty-srcs {
      [#metadata(d) <meta:dirty-file>]
    }
  }

  (
    emit-code-file-meta: emit-code-file-meta,
    emit-dirty-file-meta: emit-dirty-file-meta,
  )
}
