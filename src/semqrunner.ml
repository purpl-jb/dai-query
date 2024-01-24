open Core
open Syntax

module Dom = Domain.Array_bounds 
(* Itv Array_bounds *)

module Daig = Analysis.Daig.Make(Dom)
module SemqrDaig = Semquery.Processor.MakeForDaig(Dom)(Daig)
module Printer = Semquery.Printer.Make(Dom)

(*
The program takes one argument -- the name of a .java file.

The program loads the file into a daig, dumping its visual representation,
and starts a simple REPL.

The REPL expects an integer representing a DAIG location and
prints out the abstract state at the location.

Note: the analysis domain is hard-coded as [Dom] above.
*)

(* ============================== Processing one request *)

let process_location (daig : Daig.t) (loc : int) : unit =
  let oabsst = SemqrDaig.read_absst_by_intloc_unsafe loc daig in
  Printer.println_option_absst oabsst

let process_location_request (daig : Daig.t) (request : string) : unit =
  try 
    let loc = int_of_string request in
    try process_location daig loc 
    with Daig.Ref_not_found _ -> 
      print_endline @@ "ERROR: no location " ^ request
  with Failure _ -> 
    print_endline "ERROR: integer expected"

let process_request (daig : Daig.t) (request : string) : bool =
  match request with 
  | "exit" -> false
  | _ -> process_location_request daig request; true


(* ============================== REPL *)

let run_repl_iter (daig : Daig.t) : bool =
  print_string "> ";
  Stdlib.read_line ()
  |> process_request daig

let rec run_repl (daig : Daig.t) : unit =
  if run_repl_iter daig
  then run_repl daig
  else ()


(* ============================== Main program *)

let mk_dotps_fnames (fname : string) =
  let noext = Stdlib.Filename.remove_extension fname in
  (noext ^ ".dot", noext ^ ".ps")

let load_daig (fname : string) : Daig.t =
  print_string @@ "Loading main DAIG... ";
  let (fn, _cfg, daig) = SemqrDaig.load_main_cfg_daig fname in 
  print_endline @@ Format.sprintf "loaded: entry %s, exit %s" 
    (Cfg.Loc.to_string fn.entry) (Cfg.Loc.to_string fn.exit);
  let (dotname, psname) = mk_dotps_fnames fname in
  print_endline @@ "Dumping DAIG to " ^ dotname;
  Daig.dump_dot ~filename:dotname daig;
  print_string @@ "Converting .dot to " ^ psname ^ "... ";
  let psres = Sys.command ("dot -Tps '" ^ dotname ^ "' -o '" ^ psname ^ "'") in
  print_endline @@ "exit status: " ^ string_of_int psres;
  daig

let main fname = 
  print_endline @@ "Processing " ^ fname;
  let daig = load_daig fname in
  print_endline @@ "Starting REPL: enter location number or exit";
  run_repl daig;
  print_endline "Exiting"

(* ============================== Dealing with command-line arguments *)

let fname_param =
  let open Command.Param in
  anon ("<.java-file>" %: string)

let command =
  Command.basic
    ~summary:"Loads the main DAIG of the file and initiates a REPL"
    (* ~readme:(fun () -> "More detailed information") *)
    (Command.Param.map fname_param ~f:(fun fname () ->
         main fname))

(* let () = print_endline "QR" *)
let () = Command.run ~version:"0.1" command
