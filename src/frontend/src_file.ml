open Dai.Import
module Ts_src_file = Tree_sitter_run.Src_file

type t = Ts_src_file.t

let path = Ts_src_file.info >> function { path; _ } -> path

let lines = Ts_src_file.lines

let of_file = Ts_src_file.load_file

let of_string s = Ts_src_file.load_string ~src_name:"given string" s

let line_offsets = lines >> Array.map ~f:(String.length >> Int.succ) >> Array.to_list

let read_fn file _byte_offset row col =
  if row < Array.length (lines file) then
    let line = Ts_src_file.safe_get_row file row ^ "\n" in
    let len = String.length line in
    if col < len then Some (String.sub line ~pos:col ~len:(len - col)) else None
  else None
