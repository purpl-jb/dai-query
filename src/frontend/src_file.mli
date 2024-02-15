type t = Tree_sitter_run.Src_file.t

val path : t -> string option

val lines : t -> string array

val of_file : string -> t

val line_offsets : t -> int list
(** return the byte offsets to the first character of each line in the input program*)

val read_fn : t -> int -> int -> int -> string option
(** create a read function to be passed to tree-sitter (see TSInput struct of tree-sitter C API) *)

val of_string: string -> t
(** create a source file from a string *)