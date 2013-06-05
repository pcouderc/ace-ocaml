
open Dom_html
open Ace_utils

let id = ref 0
module H = Hashtbl

let htbl = H.create 19

let curr_tab = ref 0
let nb_untitled = ref 0

let tabs_offset = ref 0
let len = ref 4

let tabs_list = ref []


(** Utils functions **)

let sublist list off len = 
  let rec step off len acc = function
    | [] -> if len > 0 then raise (Invalid_argument "")
      else acc
    | v :: l -> if off > 0 then step (off-1) len acc l
      else if len > 0 then
        let acc = v :: acc in 
        step off (len-1) acc l
      else acc
  in
  List.rev (step off len [] list)
      


(** **)

let init_tabs_drawing () =
  let sc_left = createTd document in
  let sc_right = createTd document in
  let new_tab = createTd document in
  ()
  

let update_tabs_drawing () = 
  (* let l = sublist !tabs_list !tabs_offset !len in *)
  (* let tab = get_element_by_id "tabs" in *)
  (* let tabs = tab##childNodes () in *)
  (* let length = tabs##length () in *)
  (* for i = 0 to length do *)
  (*   begin *)
  (*     let n = tabs##item i in *)
  (*     tab##remove n; *)
  (*   end *)
  (* done; *)
  (* let elements_list =  *)
  ()


let change_tab id =
  (* Changement du tab *)
  let title = fst (H.find htbl !curr_tab) in
  let content = get_editor_value () in
  H.replace htbl !curr_tab (title, content);
  let content = snd (H.find htbl id) in
  set_editor_value (Js.string content);

  (* Changement du focus du tab *)
  let old_tab = get_element_by_id (Format.sprintf "tabnum%d" !curr_tab) in
  old_tab##className <- Js.string "tab";
  let new_tab = get_element_by_id (Format.sprintf "tabnum%d" id) in
  new_tab##className <- Js.string "tab active";
  curr_tab := id


let rec add_tab title content =
  let i = !id in
  H.add htbl i (title, content);
  incr id;
  let tr = get_element_by_id "tabs-table" in
  let new_span_title = createSpan document in
  let new_span_close = createSpan document in
  let new_td = createSpan document in
  let tab_id = Format.sprintf "tabnum%d" i in
  new_td##id <- Js.string tab_id;
  new_td##className <- Js.string "tab";
  new_span_title##innerHTML <- Js.string title;
  new_span_title##className <- Js.string "tabtitle";
  new_span_title##onclick <- handler ( fun _ ->
    change_tab i;
    Js._true);
  new_span_close##innerHTML <- Js.string "x";
  new_span_close##className <- Js.string "tabclose";
  new_span_close##onclick <- handler ( fun _ ->
    close_tab i;
    Js._true);

  tabs_list := (i, title) :: !tabs_list;
  update_tabs_drawing ();

  Dom.appendChild new_td new_span_title;
  Dom.appendChild new_td new_span_close;
  Dom.appendChild tr new_td;
  i

and add_untitled_tab () =
  let id = !nb_untitled in
  let title =
    if id = 0 then "untitled.ml"
    else Format.sprintf "untitled%d.ml" !nb_untitled
  in
  let content = "let _ =\n  print_endline \"Hello world !\"" in
  incr nb_untitled;
  add_tab title content

and close_tab id =
  let tab_id = Format.sprintf "tabnum%d" id in
  let td = get_element_by_id tab_id in
  let tr = get_element_by_id "tabs" in
  let sibling = 
    match Js.Opt.to_option td##previousSibling with
    | Some s -> Dom_html.CoerceTo.element s
    | None -> 
      match Js.Opt.to_option td##nextSibling with
      | Some s -> Dom_html.CoerceTo.element s
      | None -> Js.Opt.empty
  in
  let next_tab =
    match Js.Opt.to_option sibling with
    | Some s -> s
    | None ->
      let t = add_untitled_tab () in
      let tab_id = Format.sprintf "tabnum%d" t in
      get_element_by_id tab_id
  in
  let next_id =
    let i = Js.to_string next_tab##id in
    let len = (String.length i) - 6 in
    int_of_string (String.sub i 6 len)
  in
  change_tab next_id;
  H.remove htbl id;
  tabs_list := List.remove_assoc id !tabs_list;
  update_tabs_drawing ();
  Dom.removeChild tr td


let _ =
  (* Création du bouton d'importation des fichiers *)
  let container = get_element_by_id "input" in
  let button = createInput
    ~name:(Js.string "importFileButton")
    ~_type:(Js.string "file")
    document
  in
  button##innerHTML <- Js.string "coucou";
  button##onchange <- handler (fun _ ->
    begin
      match Js.Optdef.to_option button##files with
      | None -> ()
      | Some fl ->
	match Js.Opt.to_option fl##item(0) with
	| None -> ()
	| Some f -> 
	  begin
	    let reader = jsnew File.fileReader () in
	    reader##onload <- Dom.handler (fun _ ->
	      let s =
		match Js.Opt.to_option
		  (File.CoerceTo.string (reader##result)) with
		  | None -> Js.string "je suis la"
		  | Some str -> str
	      in
	      let id = add_tab (Js.to_string f##name) (Js.to_string s) in
	      change_tab id;
	      Js._false);
	    reader##readAsText (( f :> (File.blob Js.t)));
	  end
    end;
    Js._true
  );
  Dom.appendChild container button;

  (* Création du bouton pour faire un nouvel onglet vide *)
  let container = get_element_by_id "divtabs" in
  let button = createInput
    ~name:(Js.string "newEmptyTab")
    ~_type:(Js.string "button")
    document
  in
  button##value <- Js.string "+";
  button##id <- Js.string "newTabButton";
  button##onclick <- handler (fun _ ->
    ignore (add_untitled_tab ());
    Js._true
  );
  Dom.appendChild container button;

  ignore (add_untitled_tab ());
  let first_tab = get_element_by_id "tabnum0" in
  first_tab##className <- Js.string "tab active"

