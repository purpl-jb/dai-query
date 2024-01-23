open Syntax
open Analysis

module MakeForDaig (Daig : Daig.Sig) = struct

  type absstate = Daig.absstate
  module Loc = Cfg.Loc

  (** Returns abstract state at [loc] of [daig].
      THROWS: If [loc] doesn't exist, throws an exception. *)
  let read_absst_by_loc (loc : Loc.t) (daig : Daig.t) : absstate option =
    Daig.read_by_loc loc daig

  (** Returns abstract state spcified by integer location [loc] of [daig].
      THROWS: If [loc] doesn't exist, throws an exception. *)
  let read_absst_by_intloc_unsafe (loc : int) (daig : Daig.t) : absstate option =
    read_absst_by_loc (Loc.of_int_unsafe loc) daig

end
