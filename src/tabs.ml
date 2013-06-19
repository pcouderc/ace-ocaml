
open Dom_html
open Ace_utils

let id = ref 0
module H = Hashtbl

let htbl = H.create 19

let curr_tab = ref 0
let nb_untitled = ref 0
let is_list_shown = ref false
let offset = ref 0
let len = ref 4



let get_line_width () =
  let container = get_element_by_id "tabline" in
  container##clientWidth

let get_line_max_width () =
  let w_sc_left = (get_element_by_id "tabscleft")##clientWidth in
  let w_sc_right = (get_element_by_id "tabscright")##clientWidth in
  let w_new_tab = (get_element_by_id "tabnewtab")##clientWidth in
  let w_show_all = (get_element_by_id "tabshowall")##clientWidth in
  let w_container = (get_element_by_id "tabs")##clientWidth in
  w_container - w_sc_left - w_sc_right - w_new_tab - w_show_all


let update_len () =
  let t_size = 105
    (* match Js.Opt.to_option (get_element_by_id "tabline")##firstChild with *)
    (* | None -> assert false *)
    (* | Some c ->  *)
    (*   let el = Dom_html.CoerceTo.element c in *)
    (*   match Js.Opt.to_option el with *)
    (*   | None -> assert false *)
    (*   | Some el -> (el##clientWidth) + 4 *)
  in
  let l_width = get_line_max_width () in
  let new_len = l_width / t_size in
  len := new_len
  
let get_tab_id_from_html tab =
  let i = Js.to_string tab##id in
  let len = (String.length i) - 6 in
  int_of_string (String.sub i 6 len)

let change_offset_from_id id =
  let tabs_childs = (get_element_by_id "tabline")##childNodes in
  (* Refresh des tabs *)
  for i=0 to tabs_childs##length do
    match Js.Opt.to_option tabs_childs##item(i) with
    | None -> ()
    | Some tab_opt ->
      match Js.Opt.to_option (Dom_html.CoerceTo.element tab_opt) with
      | None -> ()
      | Some tab ->
	let tab_id = get_tab_id_from_html tab in
	if tab_id = id then
	  offset := i
  done


let rename_tab id new_title =
  let content = snd (H.find htbl id) in
  let tab = get_element_by_id (Format.sprintf "tabnum%dtitle" id) in
  let listli = get_element_by_id (Format.sprintf "listulnum%d" id) in
  begin
    match Js.Opt.to_option (Dom_html.CoerceTo.input tab) with
    | None -> assert false
    | Some tab -> tab##value <- Js.string new_title
  end;
  listli##innerHTML <- Js.string new_title;
  H.replace htbl id (new_title, content)


let update_element_from_node n f =
  match Js.Opt.to_option (Dom_html.CoerceTo.element n) with
      | None -> ()
      | Some e -> f e

let update_input name f =
  let b = get_element_by_id name in
  match Js.Opt.to_option (Dom_html.CoerceTo.input b) with
    | None -> assert false
    | Some b -> f b



let refresh_tabs () = 
  let tabs = get_element_by_id "tabs" in
  let listtabs = get_element_by_id "listtabs" in
  let tabs_childs = (get_element_by_id "tabline")##childNodes in
  let list_childs = (get_element_by_id "listul")##childNodes in
  
  (* Refresh des tabs *)
  for i=0 to tabs_childs##length do
    match Js.Opt.to_option tabs_childs##item(i) with
    | None -> ()
    | Some tab_opt ->
        update_element_from_node tab_opt 
          (fun tab ->
	    let cssdecl = tab##style in
	    if i >= !offset && i < !offset + !len then
	      cssdecl##display <- Js.string ""	   
	    else cssdecl##display <- Js.string "none") 
  done;

  (* Refresh de la liste *)
  let is_empty = ref true in
  for i=0 to list_childs##length do
    match Js.Opt.to_option list_childs##item(i) with
    | None -> ()
    | Some li_opt ->
        update_element_from_node li_opt 
          (fun li ->
  	    let cssdecl = li##style in
  	    if i >= !offset && i < !offset + !len then
  	      cssdecl##display <- Js.string "none"
  	    else
  	      begin
	        is_empty := false;
  	        if i = !curr_tab then
  	          li##className <- Js.string "listactive"
  	        else li##className <- Js.string "";
  	        cssdecl##display <- Js.string ""
  	      end)
  done;


  (* Refresh des buttons *)  
  update_input "showAllTabs" (fun b ->
    if !is_empty then
	  begin
            b##disabled <- Js._true;
            if !is_list_shown then
              begin
		let container = get_element_by_id "listtabs" in
		container##style##display <- Js.string "none";
		is_list_shown := false
              end
	  end
	else b##disabled <- Js._false);
 
  update_input "scrollTabLeft" (fun b ->
    if !offset = 0 then
	b##disabled <- Js._true
      else b##disabled <- Js._false);
  

  update_input "scrollTabRight" (fun b ->
    let max_offset = tabs_childs##length - 1 in
      if !offset >= max_offset then
	b##disabled <- Js._true
      else b##disabled <- Js._false);
     
  (* Refresh de la position de la liste *)
  let right_pos = Format.sprintf "%dpx"
    (document##body##clientWidth - tabs##offsetLeft - tabs##clientWidth + 35)
  in
  listtabs##style##right <- Js.string right_pos



let change_tab id =
  (* Changement du tab *)
  let es = snd (H.find htbl id) in
  change_edit_session es;

  (* Changement du focus du tab *)
  let old_tab = get_element_by_id (Format.sprintf "tabnum%d" !curr_tab) in
  old_tab##className <- Js.string "tab";
  let new_tab = get_element_by_id (Format.sprintf "tabnum%d" id) in
  new_tab##className <- Js.string "tab active";
  curr_tab := id


let rec add_tab title content =
  (* Choix de l'id *)
  let i = !id in
  let es = create_edit_session content in
  H.add htbl i (title, es);
  incr id;

  (* Création du tab *)
  let line = get_element_by_id "tabline" in
  let new_tab = createTd document in
  let id = Format.sprintf "tabnum%d" i in
  let span_title = createInput
    ~name:(Js.string id)
    ~_type:(Js.string "text")
    document in
  let span_close = createSpan document in
  new_tab##id <- Js.string id;
  new_tab##className <- Js.string "tab";
  span_title##id <- Js.string (id^"title");
  span_title##value <- Js.string title;
  span_title##readOnly <- Js._true;
  span_title##className <- Js.string "tabtitle";
  span_title##onclick <- handler ( fun _ ->
    if !curr_tab <> i then
      change_tab i;
    Js._true);
  span_title##ondblclick <- handler ( fun _ ->
    span_title##readOnly <- Js._false;
    Js._true);
  ignore (Dom_html.addEventListener
    span_title 
    (Dom_html.Event.make "blur")
    (handler (fun _ ->
      span_title##readOnly <- Js._true;
      rename_tab i (Js.to_string span_title##value);
      Js._true))
    Js._true);
  span_title##onkeypress <- handler (fun kev ->
    if kev##keyCode == 13 then
      (span_title##readOnly <- Js._true;
       rename_tab i (Js.to_string span_title##value));
    Js._true);
  span_close##innerHTML <- Js.string "x";
  span_close##className <- Js.string "tabclose";
  span_close##onclick <- handler ( fun _ ->
    close_tab i;
    Js._true);

  Dom.appendChild new_tab span_title;
  Dom.appendChild new_tab span_close;
  Dom.appendChild line new_tab;


  (* Création de l'item de la liste des tabs *)
  let listul = get_element_by_id "listul" in
  let li_tab = createLi document in
  let id = Format.sprintf "listulnum%d" i in
  li_tab##id <- Js.string id;
  li_tab##innerHTML <- Js.string title;
  li_tab##style##display <- Js.string "none";
  li_tab##onclick <- handler ( fun _ ->
    change_tab i;
    is_list_shown := false;
    let listtabs = get_element_by_id "listtabs" in
    listtabs##style##display <- Js.string "none";
    change_offset_from_id i;
    refresh_tabs ();
    Js._true);

  Dom.appendChild listul li_tab;


  let nbtabs = H.length htbl in
  if !offset + !len < nbtabs then
      offset := nbtabs - !len;
  refresh_tabs ();
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
  let tab = get_element_by_id tab_id in
  let line = get_element_by_id "tabline" in
  let list = get_element_by_id "listul" in
  let tabli = get_element_by_id (Format.sprintf "listulnum%d" id) in

  if !curr_tab = id then
    begin
    (* Choix du prochain tab à afficher *)
      let sibling =
	match Js.Opt.to_option tab##previousSibling with
	| Some s -> Dom_html.CoerceTo.element s
	| None -> 
	  begin
	    match Js.Opt.to_option tab##nextSibling with
	    | Some s -> Dom_html.CoerceTo.element s
	    | None -> Js.Opt.empty
	  end
      in
      let next_tab =
	match Js.Opt.to_option sibling with
	| Some s -> s
	| None ->
	  let t = add_untitled_tab () in
	  let tab_id = Format.sprintf "tabnum%d" t in
	  get_element_by_id tab_id
      in
      let next_id = get_tab_id_from_html next_tab in
      change_tab next_id
    end;
  
  H.remove htbl id;
  Dom.removeChild line tab;
  Dom.removeChild list tabli;
  refresh_tabs ()




let init_tabs_drawing () =
  let container = get_element_by_id "tabs" in
  let table = createTable document in
  let line = createTr document in
  let sc_left = createSpan document in
  let sc_right = createSpan document in
  let new_tab = createSpan document in
  let show_all = createSpan document in

  let button = createInput ~_type:(Js.string "button") document in
  button##value <- Js.string "+";
  button##id <- Js.string "newEmptyTab";
  button##onclick <- handler (fun _ ->
    let id = add_untitled_tab () in
    change_tab id;    
    Js._true);
  Dom.appendChild new_tab button;

  let button = createInput ~_type:(Js.string "button") document in
  button##value <- Js.string "<";
  button##id <- Js.string "scrollTabLeft";
  button##onclick <- handler (fun _ ->
    offset := max 0 (!offset-1);
    refresh_tabs ();
    Js._true);
  Dom.appendChild sc_left button;

  let button = createInput ~_type:(Js.string "button") document in
  button##value <- Js.string ">";
  button##id <- Js.string "scrollTabRight";
  button##onclick <- handler (fun _ ->
    let nbmax = H.length htbl in
    offset := min (nbmax-1) (!offset+1);
    refresh_tabs ();  
    Js._true);
  Dom.appendChild sc_right button;

  let button = createInput ~_type:(Js.string "button") document in
  button##value <- Js.string "...";
  button##id <- Js.string "showAllTabs";
  button##onclick <- handler (fun _ ->
    let container = get_element_by_id "listtabs" in
    let s = if !is_list_shown then "none" else "" in
    container##style##display <- Js.string s;
    is_list_shown := not !is_list_shown;
    Js._true);
  Dom.appendChild show_all button;

  line##id <- Js.string "tabline";
  table##id <- Js.string "tabtable";
  table##className <- Js.string "tabwidget";
  sc_left##id <- Js.string "tabscleft";
  sc_left##className <- Js.string "tabwidget";
  sc_right##id <- Js.string "tabscright";
  sc_right##className <- Js.string "tabwidget";
  new_tab##id <- Js.string "tabnewtab";
  new_tab##className <- Js.string "tabwidget";
  show_all##id <- Js.string "tabshowall";
  show_all##className <- Js.string "tabwidget";

  ignore(Dom_html.addMousewheelEventListener
    container
    (fun _ ~dx ~dy ->
      let dir = dx < 0 || dy > 0 in
      let nbmax = H.length htbl in
      if dir && !offset < nbmax-1 then
	(incr offset;
	 refresh_tabs ())
      else if not dir && !offset > 0 then
	(decr offset;
	 refresh_tabs ());
      Js._true)
    Js._true);

  Dom.appendChild table line;
  Dom.appendChild container sc_left; 
  Dom.appendChild container table;
  Dom.appendChild container sc_right;
  Dom.appendChild container new_tab;
  Dom.appendChild container show_all



let init_listtabs () =
  let container = get_element_by_id "listtabs" in
  let ul = createUl document in
  ul##id <- Js.string "listul";
  container##style##display <- Js.string "none";
  container##style##position <- Js.string "absolute";
  Dom.appendChild container ul
  


let main () =

  (* Création du bouton d'importation des fichiers *)
  let container = get_element_by_id "input" in
  let button = createInput
    ~name:(Js.string "importFileButton")
    ~_type:(Js.string "file")
    document
  in
  button##innerHTML <- Js.string "coucou";
  button##setAttribute(Js.string "multiple", Js.string "multiple");
  button##onchange <- handler (fun _ ->
    begin
      match Js.Optdef.to_option button##files with
      | None -> ()
      | Some fl ->
	for i=0 to fl##length do
	  match Js.Opt.to_option fl##item(i) with
	  | None -> ()
	  | Some f -> 
	    begin
	      let reader = jsnew File.fileReader () in
	      reader##onload <- Dom.handler (fun _ ->
		let s =
		  match Js.Opt.to_option
		    (File.CoerceTo.string (reader##result)) with
		    | None -> assert false
		    | Some str -> str
		in
		let id = add_tab (Js.to_string f##name) (Js.to_string s) in
                Completion_js.add_words_from_string s;
		change_tab id;
		Js._false);
	      reader##readAsText (( f :> (File.blob Js.t)));
	    end
	done
    end;
    Js._true
  );
  Dom.appendChild container button;

  (* Création des tabs *)
  init_tabs_drawing ();
  init_listtabs ();
  ignore (add_untitled_tab ());
  change_tab 0;
  (* let first_tab = get_element_by_id "tabnum0" in *)
  (* first_tab##className <- Js.string "tab active"; *)


  (* Création de l'event pour recalculer le nb de tab affiché
     à la redimention de la fenêtre *)
  update_len ();
  Dom_html.window##onresize <- Dom_html.handler
    (fun _ -> update_len ();
      refresh_tabs ();
      Js._true)



