open Dai.Import
open Syntax
open Frontend
open Analysis
open Domain

exception SemQueryError of string

(**
A wrapper around DAIG and DSG functionality for performing
semantic queries over [Dom] domain.
*)
module Make (Dom : Abstract.Dom) = struct

  module Dsg = Dsg.Make(Dom)
  module Daig = Dsg.D
  module Loc = Cfg.Loc

  type daig_info = Cfg.Fn.t * Cfg.t * Daig.t
  type absstate = Dom.t

  (** Loads intra-procedural DAIGs for functions declared in [fname].
      ASSUMES: [fname] exists.
      THROWS *)
  let load_daigs (fname : string) : daig_info list = 
    let ({ cfgs; _ } : Cfg_parser.prgm_parse_result) =
		  Cfg_parser.parse_file_exn fname
		in
		Map.to_alist cfgs
		|> List.map ~f:(fun (fn, cfg) ->
          let daig = Daig.of_cfg ~entry_state:(Dom.init ()) ~cfg ~fn in
          let _, analyzed_daig = Daig.get_by_loc fn.exit daig in
          (fn, cfg, analyzed_daig)
       )

  (** Loads an intra-procedural DAIG for the main function in [fname].
      ASSUMES: [fname] exists.
      THROWS *)
  let load_main_cfg_daig (fname : string) : daig_info =
    let is_main_daig (fn, _cfg, _daig) = Cfg.Fn.is_main_fn fn in
    let main_daig_list = List.filter ~f:is_main_daig (load_daigs fname) in
    match main_daig_list with 
    | [ daiginfo ] -> daiginfo
    | [] -> raise (SemQueryError "No main daig")
    | _  -> raise (SemQueryError "Multiple main daigs")

  (** Extracts a daig for [fn] and [entry_state] from [dsg].
      THROWS *)
  let get_cfg_daig_from_dsg (fn : Cfg.Fn.t) (entry_state : Dom.t) 
    (dsg : Dsg.t) : Cfg.t * Daig.t 
  =
    let cfg, daigs = Map.find_exn dsg fn in
    match Map.find daigs entry_state with
    | Some daig -> (cfg, daig)
    | None -> raise (SemQueryError "No daig for the given function and entry state")

  (** Loads a DAIG for the main function in [fname],
      performing inter-procedural analysis using a callgraph in [cg_fname].
      ASSUMES: [fname] and [cg_fname] exist.
      THROWS *)
  let load_main_cfg_daig_dsg (fname : string) (cg_fname : string) =
    let ({ cfgs; fields; _ } : Cfg_parser.prgm_parse_result) =
		  Cfg_parser.parse_file_exn fname
		in
    let dsg : Dsg.t = Dsg.init ~cfgs in
		let fns = Syntax.Cfg.Fn.Map.keys dsg in
		let main_fn = List.find_exn fns ~f:Cfg.Fn.is_main_fn in
    let entry_state = Dom.init () in
    let _, dsg = Dsg.materialize_daig ~fn:main_fn ~entry_state dsg in
		let cg = Callgraph.deserialize ~fns (Src_file.of_file cg_fname) in
    let _, dsg =
		  Dsg.query ~fn:main_fn ~entry_state ~loc:main_fn.exit ~cg ~fields dsg
		in 
    let main_cfg, main_daig = get_cfg_daig_from_dsg main_fn entry_state dsg in
    (main_fn, main_cfg, main_daig, dsg)

  (** Returns abstract state at [loc] of [daig].
      THROWS: If [loc] doesn't exist, throws an exception. *)
  let read_absst_by_loc (loc : Loc.t) (daig : Daig.t) : absstate option =
    Daig.read_by_loc loc daig

  (** Returns abstract state specified by integer location [loc] of [daig].
      THROWS: If [loc] doesn't exist, throws an exception. *)
  let read_absst_by_intloc_unsafe (loc : int) (daig : Daig.t) : absstate option =
    read_absst_by_loc (Loc.of_int_unsafe loc) daig

end
