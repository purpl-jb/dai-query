# Demanded Abstract Interpretation with Queries

_Incremental_ and _demand-driven_ abstract interpretation framework in OCaml

DAI requires:
 * OCaml version 4.09.0+ (definitely works with 4.13.1)
 * OPAM version 2.0.7+
 * Dune version 2.5.1+
 * System packages: libgmp-dev libmpfr-dev (for APRON numerical domains)
 * [Adapton](https://github.com/plum-umd/adapton.ocaml) version 0.1-dev (pinned as a local OPAM package via `make install`, per its README)
 * **[UPD]** Tree sitter for Java (see instructions below)

Build with `make build`.

**Tree sitter for Java**
- use `git clone --recursive` or run `git submodule update --init` after
  regular cloning of https://github.com/semgrep/ocaml-tree-sitter-languages
- run `core/scripts/install-tree-sitter-lib` to install tree-sitter library
- go to `core/src/run` and update `Src_file.ml` and `Src_file.mli` with
  `let lines x = x.lines` and `val lines : t -> string array`, respectively
- according to instructions [here](https://github.com/semgrep/ocaml-tree-sitter-languages),
  run `make setup`, and then `make` and `make install`
- from `lang`, run `./test-lang java`
- from `lang/java`, run `make` and `make install`

**Note.** Compared to the forked repo, in file `src/frontend/dune`,
the library `tree_sitter_java` is replaced with `tree-sitter-lang.java`.
