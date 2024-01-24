open Dai.Import
open Syntax
open Frontend
open Analysis
open Domain

exception SemQueryError of string

module MakeForDaig 
  (Dom : Abstract.Dom) 
  (Daig : Daig.Sig with type absstate = Dom.t) = 
struct

  type daig_info = Cfg.Fn.t * Cfg.t * Daig.t
  type absstate = Daig.absstate
  module Loc = Cfg.Loc

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

  let load_main_cfg_daig (fname : string) : daig_info =
    let is_main_daig (fn, _cfg, _daig) = Cfg.Fn.is_main_fn fn in
    let main_daig_list = List.filter ~f:is_main_daig (load_daigs fname) in
    match main_daig_list with 
    | [ daiginfo ] -> daiginfo
    | [] -> raise (SemQueryError "No main daig")
    | _  -> raise (SemQueryError "Multiple main daig")
      

  (** Returns abstract state at [loc] of [daig].
      THROWS: If [loc] doesn't exist, throws an exception. *)
  let read_absst_by_loc (loc : Loc.t) (daig : Daig.t) : absstate option =
    Daig.read_by_loc loc daig

  (** Returns abstract state spcified by integer location [loc] of [daig].
      THROWS: If [loc] doesn't exist, throws an exception. *)
  let read_absst_by_intloc_unsafe (loc : int) (daig : Daig.t) : absstate option =
    read_absst_by_loc (Loc.of_int_unsafe loc) daig

end
