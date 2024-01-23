open Domain

module Make (Dom : Abstract.Dom)  = struct
  
  let string_of_option_absst = function
    | (Some absst) -> Format.asprintf "%a" Dom.pp absst
    | None -> "None"

  let println_option_absst (oas : Dom.t option) =
    print_endline @@ string_of_option_absst oas

end
