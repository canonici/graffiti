open Eliom_pervasives
open HTML5.M
open Server

let static_dir = "local/var/www/static/"

let image_dir name =
  let dir = static_dir ^ "/graffiti_saved/" ^ (Url.encode name) in
  Lwt.catch (fun () -> Lwt_unix.mkdir dir 0o777)
    (fun _ -> debug "could not create the directory %s" dir; Lwt.return ()) >|=
  (fun () -> dir)

let make_filename name number =
  image_dir name >|= ( fun dir -> (dir ^ "/" ^ (string_of_int number) ^ ".png") )

let save image name number =
  make_filename name number >>=
    ( fun file_name ->
      Lwt_io.open_file ~mode:Lwt_io.output file_name >>=
	( fun out_chan -> Lwt_io.write out_chan image ) )

let image_info_table = Ocsipersist.open_table "image_info_table"

let save_image username =
  let now = CalendarLib.Calendar.now () in
  Lwt.catch
    (fun () -> Ocsipersist.find image_info_table username)
    (function Not_found -> Lwt.return (0,now,[]) | e -> Lwt.fail e )
  >>= ( fun (number,_,list) ->
    (Ocsipersist.add image_info_table username (number+1,now,(number,now)::list))
    >>= ( fun () ->
      let (_,image_string) = Hashtbl.find graffiti_info username in
      save (image_string ()) username number ))

let save_image_box name =
  let save_image_service =
    Eliom_output.Action.register_post_coservice'
      ~post_params:Eliom_parameters.unit
      (fun () () -> save_image name)
  in
  Eliom_output.Html5.post_form save_image_service
    (fun _ ->
      [p [Eliom_output.Html5.string_input
             ~input_type:`Submit ~value:"save" ()]]) ()

let feed_service = Eliom_services.service ~path:["feed"]
  ~get_params:(Eliom_parameters.string "name") ()

let local_filename name number =
  ["graffiti_saved"; Url.encode name ; (string_of_int number) ^ ".png"]

let rec entries name list = function
  | 0 -> []
  | len ->
    match list with
      | [] -> []
      | (n,saved)::q ->
	let title = Atom_feed.plain ("graffiti " ^ name ^ " " ^ (string_of_int n)) in
	let uri =
	  Eliom_uri.make_string_uri ~absolute:true ~service:(Eliom_services.static_dir ())
	    (local_filename name n)
	in
	let entry =
	  Atom_feed.entry ~title ~id:uri ~updated:saved
            [Atom_feed.xhtmlC [ XHTML.M.img ~src:uri ~alt:"image" ()]] in
	entry::(entries name q (len - 1))

let feed name () =
  debug "feed %s" name;
  let id = Eliom_uri.make_string_uri ~absolute:true ~service:feed_service name in
  let title = Atom_feed.plain ("nice drawings of " ^ name) in
  Lwt.catch
    (fun () -> Ocsipersist.find image_info_table name >|=
	(fun (number,updated,list) -> Atom_feed.feed ~id ~updated ~title (entries name list 10)))
    ( function Not_found ->
      let now = CalendarLib.Calendar.now () in
      Lwt.return (Atom_feed.feed ~id ~updated:now ~title [])
      | e -> Lwt.fail e )

let feed name () =
  let id = Eliom_uri.make_string_uri ~absolute:true ~service:feed_service name in
  let title = Atom_feed.plain ("nice drawings of " ^ name) in
  Lwt.catch
    (fun () -> Ocsipersist.find image_info_table name >|=
	(fun (number,updated,list) -> Atom_feed.feed ~id ~updated ~title (entries name list 10)))
    ( function Not_found ->
      let now = CalendarLib.Calendar.now () in
      Lwt.return (Atom_feed.feed ~id ~updated:now ~title [])
      | e -> Lwt.fail e )

let () = Eliom_atom.Reg.register
  ~service:feed_service feed
