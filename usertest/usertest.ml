open Dai.Import

module Test (Dom : Domain.Abstract.Dom) = struct
  module SemqrProc = Semquery.Processor.Make(Dom)
  module Printer = Semquery.Printer.Make(Dom)
  module Daig = SemqrProc.Daig
	module Dsg = SemqrProc.Dsg
	
	let dname = "usertest/"

  let entry_state = Dom.init ()

  (* JB: this code is mostly copied from src/analysis/daig.ml *)
	let test_simple fname = 
		let ({ cfgs; _ } : Frontend.Cfg_parser.prgm_parse_result) =
		  Frontend.Cfg_parser.parse_file_exn (abs_of_rel_path (dname ^ fname ^ ".java"))
		in
		Map.to_alist cfgs
		|> List.iter ~f:(fun (fn, cfg) ->
          let daig = Daig.of_cfg ~entry_state ~cfg ~fn in
          let fname_ = fname ^ "_" in
          Daig.dump_dot ~filename:(abs_of_rel_path ("initial_" ^ fname_ ^ fn.method_id.method_name ^ ".dot")) daig;
          (* prints the location of the function exit *)
          print_endline @@ Format.asprintf "%s.%s exit loc: %a" fname fn.method_id.method_name Syntax.Cfg.Loc.pp fn.exit;
          let _, analyzed_daig = Daig.get_by_loc fn.exit daig in
          Daig.dump_dot
            ~filename:(abs_of_rel_path ("analyzed_" ^ fname_ ^ fn.method_id.method_name ^ ".dot"))
            analyzed_daig
          ;
          (* reads and prints the abstrate state at the function exit *)
          Printer.println_option_absst @@
            SemqrProc.read_absst_by_loc fn.exit analyzed_daig
       );
		true
		
	(* JB: this code is mostly copied from src/analysis/dsg.ml *)
	let test_interprocedural_files files = 
		let ({ cfgs; fields; _ } : Frontend.Cfg_parser.prgm_parse_result) =
		  Frontend.Cfg_parser.parse_files_exn ~files:(List.map ~f:(fun name -> (abs_of_rel_path (dname ^ name ^ ".java"))) files)
		in
    let fname = (List.hd_exn files) in
		let dsg : Dsg.t = Dsg.init ~cfgs in
		let fns = Syntax.Cfg.Fn.Map.keys dsg in
		let main_fn = List.find_exn fns ~f:Syntax.Cfg.Fn.is_main_fn in
		let _, dsg = Dsg.materialize_daig ~fn:main_fn ~entry_state dsg in
    let _ = Dsg.dump_dot ~filename:(abs_of_rel_path ("initial_" ^ fname ^ ".dsg.dot")) dsg in
		let cg =
		  Frontend.Callgraph.deserialize ~fns (Frontend.Src_file.of_file @@ abs_of_rel_path (dname ^ fname ^ ".callgraph"))
		in
		let _exit_state, dsg =
		  Dsg.query ~fn:main_fn ~entry_state ~loc:main_fn.exit ~cg ~fields dsg
		in
    let _, main_daig = SemqrProc.get_cfg_daig_from_dsg main_fn (Dom.init ()) dsg in
    print_endline @@ Format.asprintf "%s.%s exit loc: %a" fname main_fn.method_id.method_name Syntax.Cfg.Loc.pp main_fn.exit;
    Printer.println_option_absst @@
            SemqrProc.read_absst_by_loc main_fn.exit main_daig;
		let _ = Dsg.dump_dot ~filename:(abs_of_rel_path ("solved_" ^ fname ^ ".dsg.dot")) dsg in
		true

    let test_interprocedural fname =
      test_interprocedural_files [fname]
end

(* Domain modules we've tried:
- Domain.Itv
- Domain.Array_bounds
*)

module TestInt = Test (Domain.Itv)
module TestArrBounds = Test (Domain.Array_bounds)
module TestOct = Test (Domain.Octagon)
module TestOctArrBounds = Test (Domain.Oct_array_bounds)
module TestNull = Test (Domain.Null_dom)

let%test "User test: simple sum and if with intervals" =
  TestInt.test_simple "Sum"

let%test "User test: simple for-loop with intervals" =
  TestInt.test_simple "ForLoop"
  
let%test "User test: simple static arrays with array bounds" =
  TestArrBounds.test_simple "ArrayFun"

let%test "User test: double arrays with array bounds" =
  TestArrBounds.test_simple "Double"

let%test "User test: simple double matrix with array bounds" =
  TestArrBounds.test_simple "DoubleMatrixFun"

let%test "User test: simple asssignment with octagon" =
  TestOct.test_simple "SumInLoop"  

let%test "User test: interprocedural empty class with null" =
  TestNull.test_interprocedural "NullTriv"  

let%test "User test: one-call interprocedural with intervals" =
  TestInt.test_interprocedural "FunCall"

let%test "User test: interprocedural+if with intervals" =
  TestArrBounds.test_interprocedural "FunCallInIf" 

(* JB: interprocedural does not work with intervals on this file:
  apparently, due to System.out.println, because intervals didn't implement
  function calls *)
let%test "User test: simple interprocedural with array bounds" =
  TestArrBounds.test_interprocedural "SimpleFuns"
  
let%test "User test: interprocedural static arrays with array bounds" =
  TestArrBounds.test_interprocedural "ArrayFun"

let%test "User test: interprocedural with multiple files" =
  TestArrBounds.test_interprocedural_files ["MultiFile"; "SimpleFuns"]
  
let%test "User test: interprocedural array-contains with array bounds" =
  TestArrBounds.test_interprocedural "ArrayContains"

let%test "User test: interprocedural array-swap with array bounds" =
  TestArrBounds.test_interprocedural "ArraySwap"

let%test "User test: interprocedural double matrix with array bounds" =
  TestArrBounds.test_interprocedural "DoubleMatrixFun"

(* TODO: is this any better with octagons? array access removes info *)
let%test "User test: interprocedural loop with octagon array bounds" =
  TestArrBounds.test_interprocedural "SumCallInLoop"
