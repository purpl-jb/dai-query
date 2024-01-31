(* 
Mostly copied from 
https://gist.github.com/rmrt1n/d20d4b4ab3dcf3c5ff87d17118e1e2e9 
*)

open Syntax

exception SemQueryParserError of string

(* lexer *)
type token =
  | Token_int of int64
  | Token_var of string
  | Token_eq
  | Token_lt
  (*
  | Token_plus
  | Token_minus
  | Token_mul
  | Token_div
  | Token_lparen
  | Token_rparen
  *)

(* Copied from https://stackoverflow.com/a/74217005 *)
let string_to_char_list s =
  s |> String.to_seq |> List.of_seq

(* Copied from https://stackoverflow.com/a/65075207 *)
let char_list_to_string cs = String.of_seq (List.to_seq cs)

(* Copied from https://stackoverflow.com/a/49184157 *)
let is_alpha_ = function 'a' .. 'z' | 'A' .. 'Z' | '_' -> true | _ -> false
let is_digit = function '0' .. '9' -> true | _ -> false
let is_alphanumeric_ c = is_alpha_ c || is_digit c

let rec split_while (p : 'a -> bool) (xs : 'a list) =
  match xs with
  | [] -> ([], [])
  | y :: ys when p y -> let good, bad = split_while p ys in (y :: good, bad)
  | _ -> ([], xs)

let extract_value (p : char -> bool) (convert : string -> 'a) 
  (cs : char list) : 'a * char list =
  let p_list, rem_list = split_while p cs in
  let value = p_list |> char_list_to_string |> convert in
  (value, rem_list)

let get_tokens str =
  let rec next_token tokens = function
    | [] -> tokens
    | '=' :: tl -> next_token (Token_eq :: tokens) tl
    | '<' :: tl -> next_token (Token_lt :: tokens) tl
    (*
    | '+' :: tl -> next_token (Token_plus :: tokens) tl
    | '-' :: tl -> next_token (Token_minus :: tokens) tl
    | '*' :: tl -> next_token (Token_mul :: tokens) tl
    | '/' :: tl -> next_token (Token_div :: tokens) tl
    | '(' :: tl -> next_token (Token_lparen :: tokens) tl
    | ')' :: tl -> next_token (Token_rparen :: tokens) tl
    *)
    | ' ' :: tl -> next_token tokens tl
    | c :: tl when is_digit c ->
      let number, tl = extract_value is_digit Int64.of_string (c :: tl) in
      next_token (Token_int number :: tokens) tl
    | c :: tl when is_alpha_ c ->
      let var, tl = extract_value is_alphanumeric_ (fun s -> s) (c :: tl) in
      next_token (Token_var var :: tokens) tl
    | _ -> raise (SemQueryParserError "unexpected character")
  in
  let reversed = next_token [] (string_to_char_list str) in
  List.rev reversed

let make_binop left bop right =
  Ast.Expr.Binop {l = left; op = bop; r = right;}

let rec parse_factor = function
  | Token_int x :: tl -> (Ast.Expr.Lit (Ast.Lit.Int x), tl)
  | Token_var x :: tl -> (Ast.Expr.Var x, tl)
  | _ -> raise (SemQueryParserError "unknown formula structure")
  (*
  | Token_minus :: tl ->
    let (Number x, l) = parse_factor tl in
    (Number (-x), l)
  | Token_lparen :: tl ->
    let (exp, l) = parse_expr tl in
    match l with
    | Token_rparen :: tl -> (exp, tl)
    | _ -> raise (Failure "no closing parentheses")
  *)
(*
and parse_term ls =
  let (left, l) = parse_factor ls in
  match l with
  | Token_mul :: tl ->
    let (right, l) = parse_term tl in
    (Binop (left, Token_mul, right), l)
  | Token_div :: tl ->
    let (right, l) = parse_term tl in
    (Binop (left, Token_div, right), l)
  | _ -> (left, l)
*)
and parse_expr ls = 
  let (left, l) = parse_factor ls in
  match l with
  | Token_eq :: tl ->
    let (right, l) = parse_factor tl in
    (make_binop left Ast.Binop.Eq right, l)
  | Token_lt :: tl ->
    let (right, l) = parse_factor tl in
    (make_binop left Ast.Binop.Lt right, l)
  | _ -> (left, l)
  (*
  let (left, l) = parse_term ls in
  match l with
  | Token_plus :: tl ->
    let (right, l) = parse_expr tl in
    (Binop (left, Token_plus, right), l)
  | Token_minus :: tl ->
    let (right, l) = parse_expr tl in
    (Binop (left, Token_minus, right), l)
  | _ -> (left, l)
  *)

let parse_formula str = 
  let tokens = get_tokens str in
  let root, _ = parse_expr tokens in
  root
