
{client{

  (* size and orientation *)

  type orientation = Portrait | Landscape

  val get_window_size : unit -> int * int

  val get_window_orientation : unit -> orientation

  val get_size :
    < clientHeight : < get : int; .. > Js.gen_prop;
      clientWidth : < get : int; .. > Js.gen_prop; .. > Js.t ->
      int * int

  val get_document_size : unit -> int * int

  (* time *)

  val get_timestamp : unit -> float

  (* position / coordinated *)

  val get_coord :
    < clientX : < get : int; .. > Js.gen_prop;
      clientY : < get : int; .. > Js.gen_prop; .. > Js.t ->
      int * int

  (** First arg is the id of touch *)
  val get_touch_coord : int -> Dom_html.touchEvent Js.t -> int * int

  (** First arg is the target *)
  val get_local_event_coord :
    #Dom_html.element Js.t ->
    < clientX : < get : int; .. > Js.gen_prop;
      clientY : < get : int; .. > Js.gen_prop; .. > Js.t ->
    int * int

  (** First arg is the target
      The second is the index of touch *)
  val get_local_touch_event_coord :
    #Dom_html.element Js.t ->
    int ->
    Dom_html.touchEvent Js.t ->
    int * int

  (* mobile tools *)

  (** Very usefull function to slide element

      elapsed_time is the time between each call
      step is the value between each call
      current is the start value
      target is the end value
      func is the function to apply at each call *)
  val progressive_apply :
    ?elapsed_time:float ->
    ?step:int ->
    int ->
    int ->
    (int -> 'a) ->
    unit Lwt.t

  (* others *)

  val js_string_of_px : int -> Js.js_string Js.t

  (* css tools *)

  (** Allow to set transition and -webkit-transition property *)
  val set_transition : #Dom_html.element Js.t -> string -> unit

}}
