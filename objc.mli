type id
type sel

module NSPoint :
sig
  type t
  
  external make : float -> float -> t = "ocaml_objc_nspoint_make"

  external x      : t -> float = "ocaml_objc_nspoint_x"
  external y      : t -> float = "ocaml_objc_nspoint_y"
  external width  : t -> float = "ocaml_objc_nspoint_x"
  external height : t -> float = "ocaml_objc_nspoint_y"

  val pp_print : Format.formatter -> t -> unit
end

module NSRect :
sig
  type t

  external make : float -> float -> float -> float -> t = "ocaml_objc_nsrect_make"

  val make_from_origin_and_size : NSPoint.t -> NSPoint.t -> t

  external origin : t -> NSPoint.t = "ocaml_objc_nsrect_origin"
  external size   : t -> NSPoint.t  = "ocaml_objc_nsrect_size"

  val pp_print : Format.formatter -> t -> unit
end

module NSRange :
sig
  type t

  external make : nativeint -> nativeint -> t = "ocaml_objc_nsrange_make"

  external location : t -> nativeint = "ocaml_objc_nsrange_location"
  external length   : t -> nativeint = "ocaml_objc_nsrange_length"

  val pp_print : Format.formatter -> t -> unit
end

type arg = [
  | `Bool of bool
  | `Char of char
  | `Int of int
  | `Nativeint of nativeint
  | `Int64 of int64
  | `Float of float
  | `Id of id
  | `Sel of sel
  | `NSPoint of NSPoint.t
  | `NSRect of NSRect.t
  | `NSRange of NSRange.t
]

type ret = [
  | arg
  | `Void
]

type argtype = [ `Bool | `Char | `Int | `Nativeint | `Int64 | `Float | `Id | `Sel | `NSPoint | `NSRect | `NSRange ]

exception NSException of id

external sel : string -> sel = "ocaml_objc_sel"
external clas : string -> id = "ocaml_objc_clas"
external send_sel : id -> sel -> arg list -> ret = "ocaml_objc_send"
external clas_of_id : id -> id = "ocaml_objc_clas_of_id"
external nsstring : string -> id = "ocaml_objc_nsstring"
external string_of_nsstring : id -> string = "ocaml_objc_string_of_nsstring"
external string_of_sel : sel -> string = "ocaml_objc_string_of_sel"

type 'a caml_id

external caml_value : 'a caml_id -> 'a = "ocaml_objc_caml_value"
external set_caml_value : 'a caml_id -> 'a -> unit = "ocaml_objc_set_caml_value"
external caml_id    : 'a caml_id -> id = "%identity"

external def_clas :
  ?superclass:id ->
  ?class_methods:(string * argtype list * (id -> sel -> arg list)) list ->
  ?instance_methods:(string * argtype list * ('a caml_id -> sel -> arg list)) list ->
  string ->
  id =
    "ocaml_objc_def_clas"

val nil : id

val send_ret : id -> string -> arg list -> ret
val send : (ret -> 'a) -> id -> string -> arg list -> 'a

val void_ret : ret -> unit
val bool_ret : ret -> bool
val char_ret : ret -> char
val int_ret : ret -> int
val nativeint_ret : ret -> nativeint
val int64_ret : ret -> int64
val float_ret : ret -> float
val id_ret : ret -> id
val sel_ret : ret -> sel
val nspoint_ret : ret -> NSPoint.t
val nsrect_ret : ret -> NSRect.t
val nsrange_ret : ret -> NSRange.t

val nsnumber_of_int : int -> id
val nsnumber_of_nativeint : nativeint -> id
val nsnumber_of_int64 : int64 -> id
val nsnumber_of_float : float -> id
val nsnumber_of_bool : bool -> id

val int_of_nsnumber : id -> int
val nativeint_of_nsnumber : id -> nativeint
val int64_of_nsnumber : id -> int64
val float_of_nsnumber : id -> float
val bool_of_nsnumber : id -> bool

val description : id -> string

val pp_print_id : Format.formatter -> id -> unit
val pp_print_sel : Format.formatter -> sel -> unit
