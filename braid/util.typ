#let sum(arr) = arr.fold(0, (acc, x) => acc + x)

#let group-by(arr, key-fn) = {
  arr.fold((:), (acc, item) => {
    let k = key-fn(item)
    if k not in acc { acc.insert(k, ()) }
    acc.at(k).push(item)
    acc
  })
}

#let count-lines(code-str) = {
  if code-str == "" { return 0 }
  code-str.matches("\n").len() + 1
}

#let snippet-break-str = "==== snippet break ===="

#let get-extension(lang-infos, lang) = {
  lang-infos.at(lang, default: (ext: "txt")).ext
}

#let join-lines(lang-infos, lang) = (
  lang-infos.at(lang).join-line-start + " \"" + snippet-break-str + "\"",
)

#let join-str(lang-infos, lang) = "\n" + join-lines(lang-infos, lang).join("\n") + "\n"

// example `output-render` fn for lang-configs: colorizes I:/E:/O: tagged lines from tag-stdioe.py,
// stripping the tag prefix since color alone distinguishes the stream
#let colorize-stdioe-output(content) = {
  let lines = if content == "" { () } else { content.split("\n") }
  let tag-color-of(line) = if line.starts-with("I: ") {
    rgb("#3a7ecf") // stdin: light-ish blue
  } else if line.starts-with("E: ") {
    rgb("#8b3a3a") // stderr: dark-ish red
  } else if line.starts-with("O: ") {
    luma(50%) // stdout: dark gray
  } else {
    none
  }

  block(lines.map(line => {
    let color = tag-color-of(line)
    if color == none {
      raw(line, block: false)
    } else {
      text(fill: color, raw(line.slice(3), block: false))
    }
  }).join(linebreak()))
}
