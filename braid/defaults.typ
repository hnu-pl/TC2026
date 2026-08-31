#import "util.typ": snippet-break-str, colorize-stdioe-output

#let default-lang-configs = (
  python: (
    ext: "py",
    join-line-start: "print('" + snippet-break-str + "') # ",
    interactive: src => "python " + src,
    compile: none
  ),
  kotlin: (
    ext: "kt",
    join-line-start: "//",
    compile: src => "kotlinc " + src,
  ),
  kts: (
    ext: "kts",
    join-line-start: "println(\"" + snippet-break-str + "\") //",
    interactive: src => "kotlinc -cp . -script " + src,
    compile: none, // unlike `kotlin`, no compilation for `kts` scripts
  ),
  haskell: (
    ext: "hs",
    join-line-start: "--",
    compile: src => "ghc -fno-code " + src, // compile to check syntax and types only
  ),
  ghci: (
    ext: "ghci",
    join-line-start: "putStrLn \"" + snippet-break-str + "\" --",
    interactive: src => "ghci -v0 -ghci-script " + src,
    compile: none, // unlike `haskell`, no compilation for `ghci` scripts
    output-render: colorize-stdioe-output,
  ),
  prolog: (
    ext: "pl",
    join-line-start: "?- write(\"" + snippet-break-str + "\"), nl. %",
    interactive: src => "swipl -q -l " + src,
    compile: none
  ),
  makefile: (
    ext: "mk",
    join-line-start: "#",
    codly-lang: (
      name: "Makefile",
      icon: [#v(-0.1em)⚙️#v(0.1em)],
      color: none,
    ),
  ),
)

// to share same highlting config.
// both original and alias lang names should be present in `lang-configs`.
#let default-lang-aliases = (
  ghci: "haskell", // use haskell syntax highlighting for ghci scripts
  make: "makefile",
  kts: "kotlin",
)

// the default `codly-lang` value
#let default-codly-local = (
  zebra-fill: none,
  number-placement: "outside",
  number-align: right,
  number-format: n => box(width: 1em,
    align(right, scale(x:80%, text(size: 8pt, fill: luma(50%))[#n#h(-0.2em)])),
  ),
)

