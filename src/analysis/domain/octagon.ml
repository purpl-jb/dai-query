(* Copyright (c) Benno Stein, 2020
 * me@bennostein.org
 * 
 * This source code is derived in part from the Interval domain of
 * Sledge (github.com/facebook/infer ./sledge directory), which is MIT Licensed.
 * As such, this source code is licensed under the same conditions:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.

 *)

open Dai
open Import
open Apron
open Option.Monad_infix
open Syntax

type t = Oct.t Abstract1.t

(* "magic" constant bounding the dimensionality of octagons *)
let max_env_size = 15 (* JB: increased from 5 *)

let man = lazy (Oct.manager_alloc ())

let get_man () = Lazy.force man

let change_environment man oct new_env weak : t =
  (* let new_env_size = Environment.size new_env in
     let env =
       if new_env_size > max_env_size then
         let _, vars = Environment.vars new_env in
         let truncated_vars = Array.sub vars ~pos:0 ~len:max_env_size in
         Environment.make [||] truncated_vars
       else new_env
       in*)
  Abstract1.change_environment man oct new_env weak

let combine_envs x y =
  let man = get_man () in
  let x = Abstract1.minimize_environment man x in
  let y = Abstract1.minimize_environment man y in
  let new_env = Environment.lce (Abstract1.env x) (Abstract1.env y) in
  let x' = change_environment man x new_env false in
  let y' = change_environment man y new_env false in
  (x', y')

(* Do not eta-reduce!  Will break lazy manager allocation *)
let join l r =
  let l, r = combine_envs l r in
  Abstract1.join (get_man ()) l r

(* Do not eta-reduce! Will break lazy manager allocation
   APRON widening argument order is reversed from my expectation; this function widens [l] by [r],
   treating [l] as the accumulated result of previous joins/widens and [r] as the newest element of that sequence *)
let widen l r =
  let l, r = combine_envs l r in
  Abstract1.widening (get_man ()) l r

(* Do not eta-reduce!  Will break lazy manager allocation *)
let equal l r =
  let l, r = combine_envs l r in
  Abstract1.is_eq (get_man ()) l r

(* Do not eta-reduce!  Will break lazy manager allocation *)
let is_bot oct = Abstract1.is_bottom (get_man ()) oct

(* Do not eta-reduce!  Will break lazy manager allocation *)
let implies l r =
  let l, r = combine_envs l r in
  Abstract1.is_leq (get_man ()) l r

(* Do not eta-reduce!  Will break lazy manager allocation *)
let meet l r =
  let l, r = combine_envs l r in
  Abstract1.meet (get_man ()) l r

let ( <= ) = implies

let pp fs oct =
  if is_bot oct then Format.fprintf fs "bottom"
  else
    let env = Abstract1.env oct in
    Format.fprintf fs "non-bottom octagon {{%a}} with env {{%a}}" Abstract1.print oct
      (fun fs env -> Environment.print fs env)
      env

let sexp_of_t _ = failwith "Unimplemented"

let t_of_sexp _ = failwith "Unimplemented"

let top () = Abstract1.top (get_man ()) (Environment.make [||] [||])

let bottom () = Abstract1.bottom (get_man ()) (Environment.make [||] [||])

let init = top

(* given a boolean operation : [Tcons0.typ] and two operands, construct a Tcons1 encoding the constraint *)
let mk_tcons env op l r =
  (* JB: I uncommented [let r = ...] because otherwise [<] isn't computed correctly *)
  (* add tiny constant to right hand side to avoid float comparison wonkiness*)
  let r =
     if op = Tcons0.SUP then
       Texpr1.Binop
         (Texpr1.Add, r, Texpr1.Cst (Coeff.s_of_float 0.000001), Texpr1.Double, Texpr1.Zero)
     else r
  in
  let l_minus_r = Texpr1.Binop (Texpr1.Sub, l, r, Texpr1.Double, Texpr1.Zero) in
  Tcons1.make (Texpr1.of_expr env l_minus_r) op

(* abstractly evaluate boolean binary operation [l op r] at octagon [oct] by translating it to [(l - r) op 0]
    (since apron can only solve booleran constraints of that form), and intersecting the result with [oct].
    If that intersection is  ...
      ... bottom then expression is false
      ... equal to [oct] then expression is true
      ... anything else then the expression may be true or false
   Return that result as an apron interval constant: [0,0], [1,1], or [0,1] respectively.
*)
let mk_bool_binop oct op l r =
  let env = Abstract1.env oct in
  let tcons = mk_tcons env op l r in
  let tcons_array = Tcons1.array_make env 1 $> fun a -> Tcons1.array_set a 0 tcons in
  let intersection = Abstract1.meet_tcons_array (get_man ()) oct tcons_array in
  if is_bot intersection then Texpr1.Cst (Coeff.s_of_float 0.)
  else if equal intersection oct then Texpr1.Cst (Coeff.s_of_float 1.)
  else Texpr1.Cst (Coeff.i_of_float 0. 1.)

(* Convert a native AST expression into an APRON tree expression.
   [fallback] supports mutually recursive extensions, e.g. in [array_bounds.ml]
*)
let rec texpr_of_expr ?(fallback = fun _ _ -> None) oct =
  let open Ast in
  let mk_arith_binop op l r = Some (Texpr1.Binop (op, l, r, Texpr1.Double, Texpr0.Zero)) in
  let mk_bool_binop i op l r = Some (mk_bool_binop i op l r) in
  function
  | Expr.Var v ->
      let env = Abstract1.env oct in
      let apron_var = Var.of_string v in
      if Environment.mem_var env apron_var then Some (Texpr1.Var apron_var) else None
  | Expr.Lit (Int i) -> Some (Texpr1.Cst (Coeff.s_of_float (Float.of_int64 i)))
  | Expr.Lit (Float f) -> Some (Texpr1.Cst (Coeff.s_of_float f))
  | Expr.Lit (Bool b) -> Some (Texpr1.Cst (Coeff.s_of_float (if b then 1. else 0.)))
  | Expr.Lit _ -> None
  | Expr.Binop { l; op; r } -> (
      texpr_of_expr ~fallback oct l >>= fun l ->
      texpr_of_expr ~fallback oct r >>= fun r ->
      match op with
      | Plus -> mk_arith_binop Texpr1.Add l r
      | Minus -> mk_arith_binop Texpr1.Sub l r
      | Times -> mk_arith_binop Texpr1.Mul l r
      | Divided_by -> mk_arith_binop Texpr1.Div l r
      | Mod -> mk_arith_binop Texpr1.Mod l r
      | Eq -> mk_bool_binop oct Tcons0.EQ l r
      | NEq -> mk_bool_binop oct Tcons0.DISEQ l r
      | Gt -> mk_bool_binop oct Tcons0.SUP l r
      | Ge -> mk_bool_binop oct Tcons0.SUPEQ l r
      | Lt -> mk_bool_binop oct Tcons0.SUP r l
      | Le -> mk_bool_binop oct Tcons0.SUPEQ r l
      | And | Or -> Some (Texpr1.Cst (Coeff.i_of_float 0. 1.))
      | BAnd | BOr | BXor ->
          (* sending bitwise arihmetic to top because APRON does not support it *)
          Some (Texpr1.Cst (Coeff.Interval Interval.top))
      | LShift ->
          (* IR expression `l >> r` becomes APRON expression `l * (2^r)` *)
          let two_to_the_r = Texpr1.(Binop (Pow, Cst (Coeff.s_of_int 2), r, Double, Zero)) in
          Some Texpr1.(Binop (Mul, l, two_to_the_r, Double, Zero))
      | URShift | RShift ->
          (* IR expression `l >> r` becomes APRON expression `l / (2^r)` *)
          (* todo: mess with sign for unsigned shift --- this isn't quite right for negative values of [l] *)
          let two_to_the_r = Texpr1.(Binop (Pow, Cst (Coeff.s_of_int 2), r, Double, Zero)) in
          Some Texpr1.(Binop (Div, l, two_to_the_r, Double, Zero))
      | Instanceof ->
          (* result of instanceof is a bool; from interval's perspective, either a 0 or 1 *)
          Some (Texpr1.Cst (Coeff.Interval (Interval.of_int 0 1)))
      | _ ->
          Format.fprintf Format.err_formatter "Binary op %a has no APRON equivalent\n" Binop.pp op;
          None)
  (* cancel out double-negations, arithmetic and boolean *)
  | Expr.Unop { op = Unop.Neg; e = Expr.Unop { op = Unop.Neg; e } }
  | Expr.Unop { op = Unop.Not; e = Expr.Unop { op = Unop.Not; e } } ->
      texpr_of_expr ~fallback oct e
  | Expr.Unop { op; e } -> (
      (* Translate to equivalent expressions for unops with no APRON equivalent (i.e. everything but [Neg]):
       * !e -> e==0
       * +e -> e
       * e++ -> e+1
       * e-- -> e-1
       *)
      texpr_of_expr ~fallback oct e
      >>= fun e ->
      match op with
      | Unop.Neg -> Some (Texpr1.Unop (Texpr1.Neg, e, Texpr1.Double, Texpr0.Zero))
      | Unop.Not -> mk_bool_binop oct Tcons0.EQ e (Texpr1.Cst (Coeff.s_of_float 0.))
      | Unop.Plus -> Some e
      | Unop.Incr -> mk_arith_binop Texpr1.Add e (Texpr1.Cst (Coeff.s_of_float 1.))
      | Unop.Decr -> mk_arith_binop Texpr1.Sub e (Texpr1.Cst (Coeff.s_of_float 1.))
      | Unop.Typeof | Unop.BNot -> None)
  | expr -> fallback oct expr

let rec meet_with_constraint ?(fallback = fun _ _ -> None) oct =
  let open Ast.Expr in
  let man = get_man () in
  let meet_with_op oct op l r =
    texpr_of_expr ~fallback oct l
    >>= (fun l ->
          texpr_of_expr ~fallback oct r >>| fun r ->
          let tcons = mk_tcons (Abstract1.env oct) op l r in
          let tcons_array =
            Tcons1.array_make (Abstract1.env oct) 1 $> fun a -> Tcons1.array_set a 0 tcons
          in
          Abstract1.meet_tcons_array man oct tcons_array)
    |> Option.value ~default:oct
  in
  let flip_binop =
    let open Ast.Binop in
    function
    | And -> Some Or
    | Or -> Some And
    | Eq -> Some NEq
    | NEq -> Some Eq
    | Gt -> Some Le
    | Lt -> Some Ge
    | Ge -> Some Lt
    | Le -> Some Gt
    | _ -> None
  in
  function
  | Unop { op = Not; e = Binop { l; op; r } } when Option.is_some (flip_binop op) ->
      (* apply demorgans to push negations out to leaves of boolean operators; flip equalities/inequalities *)
      let new_l = if op = And || op = Or then Unop { op = Not; e = l } else l in
      let new_r = if op = And || op = Or then Unop { op = Not; e = r } else r in
      let flipped_op = Option.value_exn (flip_binop op) in
      meet_with_constraint ~fallback oct (Binop { l = new_l; op = flipped_op; r = new_r })
  | Binop { l; op = And; r } ->
      let l = meet_with_constraint ~fallback oct l in
      let r = meet_with_constraint ~fallback oct r in
      Abstract1.meet man l r
  | Binop { l; op = Or; r } ->
      let l = meet_with_constraint ~fallback oct l in
      let r = meet_with_constraint ~fallback oct r in
      Abstract1.join man l r
  | Binop { l; op = Eq; r } -> meet_with_op oct Tcons0.EQ l r
  | Binop { l; op = NEq; r } -> meet_with_op oct Tcons0.DISEQ l r
  | Binop { l; op = Gt; r } -> meet_with_op oct Tcons0.SUP l r
  | Binop { l; op = Ge; r } -> meet_with_op oct Tcons0.SUPEQ l r
  | Binop { l; op = Lt; r } -> meet_with_op oct Tcons0.SUP r l
  | Binop { l; op = Le; r } -> meet_with_op oct Tcons0.SUPEQ r l
  | Unop { op = Not; e } -> meet_with_op oct Tcons0.EQ e (Lit (Int 0L))
  | _ -> oct

let eval_texpr oct expr =
  try
    let texpr = Texpr1.of_expr (Abstract1.env oct) expr in
    Abstract1.bound_texpr (get_man ()) oct texpr
  with _ -> Apron.Interval.top

let extend_env_by_uses stmt oct =
  let env = Abstract1.env oct in
  (* JB: silently doing this is unsound! *)
  (* if Environment.size env >= max_env_size then oct *)
  if Environment.size env >= max_env_size then
    failwith "too many variables in octagon"
  else
    let man = get_man () in
    (* adding RETVAR here is a hack -- not sure why, but apron complains down the line if RETVAR
       is not in the env, including throwing an error if you try to add it explicitly. *)
    let new_uses =
      Set.add (Ast.Stmt.uses stmt) Cfg.retvar
      |> Set.filter ~f:(fun var_str -> not @@ Environment.mem_var env (Var.of_string var_str))
    in
    if Set.is_empty new_uses then oct
    else
      new_uses |> Set.to_array |> Array.map ~f:Var.of_string |> Environment.add env [||]
      |> fun new_env -> change_environment man oct new_env true

let interpret stmt oct =
  let open Ast.Stmt in
  let man = get_man () in
  let oct = extend_env_by_uses stmt oct in
  match stmt with
  | Write _ | Skip | Expr _ | Call _ -> oct
  | Assume e -> meet_with_constraint oct e
  | Assign { lhs; rhs } -> (
      let lhs = Var.of_string lhs in
      let env = Abstract1.env oct in
      (* JB: silently doing this is unsound! *)
      (* if Environment.size env >= max_env_size then oct *)
      if Environment.size env >= max_env_size then
        failwith "too many variables in octagon"
      else
        let new_env =
          if Environment.mem_var env lhs then env else Environment.add env [||] [| lhs |]
        in
        let oct_new_env = change_environment man oct new_env false in
        match texpr_of_expr oct rhs with
        | Some rhs_texpr ->
            Abstract1.assign_texpr man oct_new_env lhs (Texpr1.of_expr new_env rhs_texpr) None
        | None ->
            if Environment.mem_var env lhs then
              (* lhs was constrained, quantify that out *)
              Abstract1.forget_array man oct [| lhs |] false
            else (* lhs was unconstrained, treat as a `skip`*) oct)
  | Array_write _ | Exceptional_call _ -> failwith "todo1"

let sanitize oct = oct

let show oct =
  pp Format.str_formatter oct;
  Format.flush_str_formatter ()

let hash seed oct =
  try seeded_hash seed @@ Abstract1.hash (get_man ()) oct with Apron.Manager.Error _ -> seed

let compare l r =
  let l, r = combine_envs l r in
  let man = get_man () in
  try Abstract1.(if is_eq man l r then 0 else if is_leq man l r then -1 else 1)
  with Apron.Manager.Error { exn = _; funid = _; msg } ->
    failwith ("Apron error in Octagon#compare: " ^ msg)

let hash_fold_t h oct = Ppx_hash_lib.Std.Hash.fold_int h (hash 0 oct)

let call ~callee:_ ~callsite:_ ~caller_state:_ = failwith "todo3"

let return ~callee:_ ~caller:_ ~callsite:_ ~caller_state:_ ~return_state:_ = failwith "todo4"

let approximate_missing_callee ~caller_state:_ ~callsite:_ = failwith "todo5"
(* JB: copying something from array_bounds to allow for random booleans
let approximate_missing_callee ~caller_state ~callsite = 
  match callsite with *)


(*let handle_return ~caller_state ~return_state ~callsite ~callee_defs:_ =
  match callsite with
  | Ast.Stmt.Call { lhs; _ } -> (
      let man = get_man () in
      let lhs = Var.of_string lhs in
      let env = Abstract1.env caller_state in
      let new_env =
        if Environment.mem_var env lhs then env else Environment.add env [||] [| lhs |]
      in
      let caller_state = Abstract1.change_environment man caller_state new_env false in
      let return_val =
        try Abstract1.bound_variable man return_state (Var.of_string Cfg.retvar)
        with Apron.Manager.Error _ -> Apron.Interval.top
      in
      try
        Abstract1.assign_texpr man caller_state lhs
          Texpr1.(of_expr new_env (Cst (Coeff.Interval return_val)))
          None
      with Apron.Manager.Error _ -> caller_state )
  | _ -> failwith "malformed callsite"
*)

let filter_env (oct : t) ~(f : string -> bool) =
  let env = Abstract1.env oct in
  let _, fp_vars = Environment.vars env in
  let removed_vars = Array.filter fp_vars ~f:(Var.to_string >> f >> not) in
  let new_env = Environment.remove env removed_vars in
  change_environment (get_man ()) oct new_env false

let forget vars oct =
  let new_env = Environment.remove (Abstract1.env oct) vars in
  change_environment (get_man ()) oct new_env false

let lookup oct var =
  let man = get_man () in
  if Environment.mem_var (Abstract1.env oct) var then Abstract1.bound_variable man oct var
  else Interval.top

let assign oct var texpr =
  let man = get_man () in
  let old_env = Abstract1.env oct in
  if Environment.size old_env >= max_env_size then oct
  else
    let env = Environment.(if mem_var old_env var then old_env else add old_env [||] [| var |]) in
    let oct = change_environment man oct env false in
    Abstract1.assign_texpr man oct var Texpr1.(of_expr env texpr) None

let weak_assign oct var texpr =
  let man = get_man () in
  let old_env = Abstract1.env oct in
  if Environment.size old_env >= max_env_size then oct
  else
    let env = Environment.(if mem_var old_env var then old_env else add old_env [||] [| var |]) in
    let oct = change_environment man oct env true in
    Abstract1.join man oct (assign oct var texpr)
