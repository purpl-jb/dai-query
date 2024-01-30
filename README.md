# Demanded Abstract Interpretation with Queries

Original project:
_incremental_ and _demand-driven_ abstract interpretation framework in OCaml

Current project:
semantic queries over demanded abstract interpretation graphs


## Build

DAI requires:
 * OCaml version 4.09.0+ (definitely works with 4.13.1)
 * OPAM version 2.0.7+
 * Dune version 2.5.1+
 * System packages: libgmp-dev libmpfr-dev (for APRON numerical domains)
 * [Adapton](https://github.com/plum-umd/adapton.ocaml) version 0.1-dev (pinned as a local OPAM package via `make install`, per its README)
 * **[UPD]** Tree sitter for Java (see instructions below)

 Additionally, the project requires:
 * Graphviz (for processing `.dot` files)
 * python3 (for building callgraphs with WALA)
 * Java 8 or 11 (for building callgraphs with WALA)

Build with `make build`.

**Tree sitter for Java**
- use `git clone --recursive` or run `git submodule update --init` after
  regular cloning of https://github.com/semgrep/ocaml-tree-sitter-languages
- run `core/scripts/install-tree-sitter-lib` to install tree-sitter library
- apply [`build-aux/public-lines.patch`](build-aux/public-lines.patch) to `core`
  or go to `core/src/run` and update `Src_file.ml` and `Src_file.mli` with
  `let lines x = x.lines` and `val lines : t -> string array`, respectively
- according to instructions [here](https://github.com/semgrep/ocaml-tree-sitter-languages),
  run `make setup`, and then `make` and `make install`
- from `lang`, run `./test-lang java`
- from `lang/java`, run `make` and `make install`

**Note.** Compared to the forked repo, in file `src/frontend/dune`,
the library `tree_sitter_java` is replaced with `tree-sitter-lang.java`.


## Building callgraphs for interprocedural analyses

- `git submodule init && git submodule update`
- `cd WALA-callgraph`
- Ensure you have Java 8 or 11 installed, with gradle 7.6
- `./gradlew compileJava`

To easily build a callgraph, use the script
[`build-callgraph.py`](build-callgraph.py) (requires python3):

```
./build-callgraph.py usertest/ArrayFun.java
```

To build a callgraph manually:

- From `usertest`: 
  + `javac ArrayFun.java`
  + `jar cfe ArrayFun.jar ArrayFun ArrayFun.class`
    (make sure the resulting jar is good by `java -jar ArrayFun.jar`
    which should fail with array out of bounds).
- From WALA-callgraph: 
  `./run.py ../usertest/ArrayFun.callgraph ../usertest/ArrayFun.jar`


## Experiment with DAI

A few simple examples are in [`usertest`](usertest/): file 
[`usertest.ml`](usertest/usertest.ml) runs interval and array-bounds analyses
(currently, both ignore function calls).
Analyzed graphs are stored in `.dot` files.
- To run those examples, simply run `./run_usertest.sh`: the script
  builds the project, runs tests from [`usertest`](usertest/),
  and converts analyzed graphs to a visual representation in `.ps` files
  using Graphviz.
- The resulting graphs can be found in `_build/default/`.

### Notes on DAI's features

It seems dynamic arrays aren't supported in any capacity (searching 
`Expr.Array_create` shows that neither domains implements this construct),
so it's impossible to write any meaningful array-processing code, unfortunately.

Ouch, DAI's **array-related analysis is unsound**!
For an array inside a function, manipulating the array element removes 
it from the state. Then, the effect of the function is not reflected
in the memory state inside the main function.
See `usertest/ArraySwap.java` for an example.


## Semantic Querying

File [`src/semqrunner.ml`](src/semqrunner.ml)
provides a simple command-line interface for
exploring DAIG abstract states (see the script for more info)
for interval domain.

Run
`_build/default/src/semqrunner.exe _build/default/usertest/Sum.java`
as an example.
- if there is a callgraph file with the same name,
  `_build/default/usertest/Sum.callgraph`,
  an inter-procedural analysis is performed using a DSG;
- otherwise, only an intra-procedural analysis is performed.

## Graph exploration

### Locations

Locations originating from the control-flow graph are denoted with `l<number>`.
They can be visually identified in `.ps` files as `l<number>: <abstract state>`
in green-bordered rectangles.

Programmatically, locations have the type `Syntax.Cfg.Loc.t`.

A location with a given integer index can be obtained with
`Syntax.Cfg.Loc.of_int_unsafe`.

### Abstract state

To access abstract state at a given location, use `Analysis.Daig.read_by_loc`;
if the state isn't computed, returns `None`.

To request abstract state (and compute if not yet),
use `Analysis.Daig.get_by_loc`.
