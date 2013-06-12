(**
 ocamlc -I ~/.opam/4.00.1/lib/re re.cma re_emacs.cma re_str.cma -o autocomplete autocomplete.ml && ./autocomplete 
**)


open Completion_data

(** (* Creation functions *) **)

let reset_env () =
  actual_env := empty_env ()

let add_word = new_word

let create_from_string str =
  Completion_lexer.token (Lexing.from_string str)


let create_from_channel ch =
  Completion_lexer.token (Lexing.from_channel ch)

(** Utils functions **)

let set_to_list s =
  List.rev (Words.fold (fun elt l -> elt :: l) s [])

let set_to_array s =
  let a = Array.make (Words.cardinal s) "" in
  ignore (Words.fold (fun elt i -> a.(i) <- elt; i+1) s 0);
  a

let print_word_from_set s =
  let rec print = function
    | [] -> []
    | w :: l -> Format.printf "%s@." w; print l
  in
  print (set_to_list s)

(** Functions to compute completion **)

let find_completion w =
  let re = "^" ^ w ^ "*" in
  let re = Re_str.regexp re in
  (* let re = Re.compile re in *)
  
  let rec step env acc =
    let acc = Words.fold
      (fun s acc ->
        (* Format.printf "%s@." s; *)
        if  Re_str.string_match re s 0 then 
          begin
            Words.add s acc
          end
        else acc)
      env.actual
      acc
    in
    if env == env.parent then acc
    else step env.parent acc
  in
  step !actual_env Words.empty

let compute_completions w =
  let words = find_completion w in
  let words = set_to_array words in
  completions := words;
  actual_index := 0

let next_completion () =
  let n = !completions.(!actual_index) in
  actual_index := (!actual_index + 1) mod Array.length !completions;
  n

let _ =
  reset_env ();
  new_word "get_use";
  new_word "get_i";
  new_word "match_stg";
  let f = open_in "indentBlock.ml" in
  reset_env ();
  create_from_channel f;
  compute_completions "comp";
  let n = next_completion () in
  Format.printf "%s@." n;
  let n = next_completion () in
  Format.printf "%s@." n;
  let n = next_completion () in
  Format.printf "%s@." n

  
   
