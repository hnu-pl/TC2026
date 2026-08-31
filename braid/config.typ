#import "defaults.typ": default-lang-configs, default-lang-aliases, default-codly-local

#let build-config(config: (:)) = {
  let cfg = (: ..config)
  let lang-configs = cfg.at("lang-configs", default: default-lang-configs)
  let lang-aliases = cfg.at("lang-aliases", default: default-lang-aliases)
  let codly-local = cfg.at("codly-local", default: default-codly-local)
  let codly-lang-default = cfg.at("codly-lang-default", default: none)
  let files-db = cfg.at("files-db", default: ())
  let build-dir = cfg.at("build-dir", default: "_build")
  let typfile-path = cfg.at("typfile-path", default: "../main.typ")
  let tag-stdioe-cmd = cfg.at("tag-stdioe-cmd", default: "python ../tag-stdioe.py")

  let lang-infos = {
    lang-aliases.pairs().fold(
      lang-configs.map(c => (: ..(codly-lang: codly-lang-default), ..c)),
      (acc, pair) => {
        let alias = pair.at(0)
        let lang = pair.at(1)
        if lang not in acc {
          panic("Error: alias '" + alias + "' points to unknown language '" + lang + "'.")
        }

        let aliased = acc.at(alias, default: (:))
        let base = acc.at(lang)
        (..acc, (alias): (: ..base, ..aliased))
      }
    )
  }

  (
    config: cfg,
    lang-configs: lang-configs,
    lang-aliases: lang-aliases,
    lang-infos: lang-infos,
    codly-local: codly-local,
    files-db: files-db,
    build-dir: build-dir,
    typfile-path: typfile-path,
    tag-stdioe-cmd: tag-stdioe-cmd,
  )
}
