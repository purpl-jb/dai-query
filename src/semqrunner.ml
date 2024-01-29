open Core
open Syntax

module Dom = Domain.Itv 

module SemqrProc = Semquery.Processor.Make(Dom)
module Daig = SemqrProc.Daig
module Printer = Semquery.Printer.Make(Dom)

(*
The program takes one argument -- the name of a .java file.

The program loads the file into a daig, dumping its visual representation,
and starts a simple REPL.

The REPL processes the following commands:
- q: quit
- p <intloc>: prints out the abstract state at the DAIG location
  represented by <intloc>
- c <intloc> <formula>: checks <formula> at the DAIG location <intloc>
  where <formula> is <var>=<int>;
  [0,0] means false, [1,1] means true, [0,1] means maybe

Note: the interval analysis domain is hard-coded as [Dom] above.
*)

(* ============================== Aux *)

let println_error errstr =
  print_endline @@ "ERROR: " ^ errstr

(* ============================== Processing one request *)

(* let sample_formula = Ast.Expr.Binop { 
  l = Ast.Expr.Var "a";
  op = Ast.Binop.Eq; 
  r = Ast.Expr.Lit (Ast.Lit.Int 2L);
} *)

(* formula has to be of the form <var>=<int> *)
let parse_formula (formula : string) : Ast.Expr.t option =
  let parts = Stdlib.String.split_on_char '=' formula in
  match parts with
  | [var; intval] -> Some (Ast.Expr.Binop { 
      l = Ast.Expr.Var var;
      op = Ast.Binop.Eq; 
      r = Ast.Expr.Lit (Ast.Lit.Int (Int64.of_string intval));
    })
  | _ -> None

let eval_formula (absst : Dom.t) (formula : Ast.Expr.t) : Apron.Interval.t option =
  let otexpr = Dom.texpr_of_expr absst formula in
  match otexpr with
  | None -> None
  | Some texpr -> Some (Dom.eval_texpr absst texpr)

let process_location_request_impl
  (daig : Daig.t) ?formula (locstr : string) : unit 
=
  let loc = int_of_string locstr in
  let oabsst = SemqrProc.read_absst_by_intloc_unsafe loc daig in
  match formula with
  | None -> Printer.println_option_absst oabsst
  | Some formula -> 
      match oabsst with
      | None -> print_endline "UNKNOWN (state is None)"
      | Some absst -> 
          let oitv = Option.bind (parse_formula formula) ~f:(eval_formula absst) in 
          match oitv with
          | None -> println_error "could not parse or eval the formula"
          | Some itv -> print_endline @@
              Format.asprintf "%a" Dom.pp_interval itv

let process_location_request (daig : Daig.t) ?formula (locstr : string) : unit =
  try process_location_request_impl daig ?formula locstr with 
  | Daig.Ref_not_found _ -> 
      println_error @@ "no location " ^ locstr
  | Failure errstr -> 
      println_error errstr

let process_request (daig : Daig.t) (request : string) : unit =
  let req_list = Stdlib.String.split_on_char ' ' request in
  match req_list with 
  | ["p"; loc] -> process_location_request daig loc
  | ["c"; loc; formula] -> process_location_request daig loc ~formula
  | _ -> println_error "unknown command"

let read_and_process_request (daig : Daig.t) : bool =
  let request = Stdlib.read_line () in
  match request with 
  | "q" -> false
  | _   -> process_request daig request; true


(* ============================== REPL *)

let run_repl_iter (daig : Daig.t) : bool =
  print_string "> ";
  read_and_process_request daig

let rec run_repl (daig : Daig.t) : unit =
  if run_repl_iter daig
  then run_repl daig
  else ()


(* ============================== Main program *)


let mk_cg_fname (fname : string) =
  let noext = Stdlib.Filename.remove_extension fname in
  noext ^ ".callgraph"

let mk_dotps_fnames (fname : string) =
  let noext = Stdlib.Filename.remove_extension fname in
  (noext ^ ".dot", noext ^ ".ps")

(** Loads either a regular or an interprocedural daig for the main function
    depending on the existence of the matching .callgraph file.
    ASSUMES: fname exists *)
let load_daig_info (fname : string) : SemqrProc.daig_info =
  let cg_fname = mk_cg_fname fname in
  match Sys.file_exists cg_fname with
  | `No -> ( print_string " [no .callgraph file: simple daig] ";
      SemqrProc.load_main_cfg_daig fname
    )
  | `Unknown -> failwith @@ "Couldn't access " ^ fname
  | `Yes -> ( print_string " [.callgraph file found: using inter-procedural dsg] ";
      let (fn, cfg, daig, _dsg) = SemqrProc.load_main_cfg_daig_dsg fname cg_fname in
      (fn, cfg, daig)
    )

let load_and_dump_daig (fname : string) : Daig.t =
  print_string @@ "Loading main DAIG... ";
  let (fn, _cfg, daig) = load_daig_info fname in 
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
  match Sys.file_exists fname with
  | `No -> failwith @@ "File " ^ fname ^ " does not exist"
  | `Unknown -> failwith @@ "Couldn't access " ^ fname
  | `Yes -> (
    let daig = load_and_dump_daig fname in
    print_endline @@ "Starting REPL: enter location number or exit";
    run_repl daig
  );
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
