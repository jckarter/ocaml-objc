type id
type sel

exception NSException of id

module NSPoint =
struct
  type t
  
  external make : float -> float -> t = "ocaml_objc_nspoint_make"

  external x      : t -> float = "ocaml_objc_nspoint_x"
  external y      : t -> float = "ocaml_objc_nspoint_y"
  external width  : t -> float = "ocaml_objc_nspoint_x"
  external height : t -> float = "ocaml_objc_nspoint_y"

  let pp_print fmt v = Format.fprintf fmt "<NSPoint (%f, %f)>" (x v) (y v)
end

module NSRect =
struct
  type t

  external make : float -> float -> float -> float -> t = "ocaml_objc_nsrect_make"

  let make_from_origin_and_size origin size =
    make (NSPoint.x origin) (NSPoint.y origin) (NSPoint.width size) (NSPoint.height size)

  external origin : t -> NSPoint.t = "ocaml_objc_nsrect_origin"
  external size   : t -> NSPoint.t  = "ocaml_objc_nsrect_size"

  let pp_print fmt v =
    let o = (origin v) in
    let s = (size v) in
      Format.fprintf fmt "<NSRect origin (%f, %f) size (%f, %f)>"
          (NSPoint.x o) (NSPoint.y o) (NSPoint.width s) (NSPoint.height s)
end

module NSRange =
struct
  type t

  external make : nativeint -> nativeint -> t = "ocaml_objc_nsrange_make"

  external location : t -> nativeint = "ocaml_objc_nsrange_location"
  external length   : t -> nativeint = "ocaml_objc_nsrange_length"

  let pp_print fmt v =
     Format.fprintf fmt "<NSRange location %nd length %nd>" (location v) (length v)
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

external _initialize : unit -> unit = "ocaml_objc_initialize"
external _finalize : unit -> unit = "ocaml_objc_finalize"
external _nil : unit -> id = "ocaml_objc_nil"
external sel : string -> sel = "ocaml_objc_sel"
external clas : string -> id = "ocaml_objc_clas"
external send_sel : id -> sel -> arg list -> ret = "ocaml_objc_send"
external clas_of_id : id -> id = "ocaml_objc_clas_of_id"
external nsstring : string -> id = "ocaml_objc_nsstring"
external string_of_nsstring : id -> string = "ocaml_objc_string_of_nsstring"
external string_of_sel : sel -> string = "ocaml_objc_string_of_sel"

type 'a caml_id = id

external set_caml_value : 'a caml_id -> 'a -> unit = "ocaml_objc_set_caml_value"
external caml_value : 'a caml_id -> 'a = "ocaml_objc_caml_value"
external caml_id    : 'a caml_id -> id = "%identity"

external def_clas :
  ?superclass:id ->
  string ->
  (sel * argtype list * (id -> sel -> arg list)) list ->
  id =
    "ocaml_objc_def_clas"

let nil = _nil ()

let _ = (
  Callback.register_exception "NSException" (NSException nil);
  at_exit _finalize;
  _initialize ();
)

let send_ret o msg args = send_sel o (sel msg) args
let send ret o msg args = ret (send_ret o msg args)

let bool_ret = function
  | `Bool b -> b
  | `Char c -> c != '\000'
  | _ -> failwith "bool_ret wasn't given bool"

let char_ret = function
  | `Bool b -> if b then '\001' else '\000'
  | `Char c -> c
  | _ -> failwith "char_ret wasn't given char"

let int_ret = function
  | `Bool b -> if b then 1 else 0
  | `Char c -> int_of_char c
  | `Int i -> i
  | `Nativeint i -> Nativeint.to_int i
  | `Int64 i -> Int64.to_int i
  | _ -> failwith "int_ret wasn't given int"

let nativeint_ret = function
  | `Bool b -> if b then 1n else 0n
  | `Char c -> Nativeint.of_int (int_of_char c)
  | `Int i -> Nativeint.of_int i
  | `Nativeint i -> i
  | `Int64 i -> Int64.to_nativeint i
  | _ -> failwith "nativeint_ret wasn't given int"

let int64_ret = function
  | `Bool b -> if b then 1L else 0L
  | `Char c -> Int64.of_int (int_of_char c)
  | `Int i -> Int64.of_int i
  | `Nativeint i -> Int64.of_nativeint i
  | `Int64 i -> i
  | _ -> failwith "int64_ret wasn't given int"

let float_ret = function
  | `Float f -> f
  | _ -> failwith "float_ret wasn't given float"

let id_ret = function
  | `Id o -> o
  | _ -> failwith "id_ret wasn't given id"

let sel_ret = function
  | `Sel s -> s
  | _ -> failwith "sel_ret wasn't given sel"

let nspoint_ret = function
  | `NSPoint p -> p
  | _ -> failwith "nspoint_ret wasn't given NSPoint.t"

let nsrect_ret = function
  | `NSRect r -> r
  | _ -> failwith "nsrect_ret wasn't given NSRect.t"

let nsrange_ret = function
  | `NSRange r -> r
  | _ -> failwith "nsrange_ret wasn't given NSRange.t"

let void_ret = function
  | `Void -> ()
  | _ -> failwith "void_ret wasn't given Void"

let nsnumber_of_int i =
  send id_ret (clas "NSNumber") "numberWithLong:" [`Int i]
let nsnumber_of_nativeint i =
  send id_ret (clas "NSNumber") "numberWithLong:" [`Nativeint i]
let nsnumber_of_int64 i =
  send id_ret (clas "NSNumber") "numberWithLongLong:" [`Int64 i]
let nsnumber_of_float f =
  send id_ret (clas "NSNumber") "numberWithFloat:" [`Float f]
let nsnumber_of_bool b =
  send id_ret (clas "NSNumber") "numberWithBool:" [`Bool b]

let int_of_nsnumber o =
  send int_ret o "longValue" []
let nativeint_of_nsnumber o =
  send nativeint_ret o "longValue" []
let int64_of_nsnumber o =
  send int64_ret o "longLongValue" []
let float_of_nsnumber o =
  send float_ret o "floatValue" []
let bool_of_nsnumber o =
  send bool_ret o "boolValue" []

let description o =
  string_of_nsstring(send id_ret o "description" [])

let pp_print_id formatter o =
  Format.fprintf formatter "<id \"%s\">" (description o)

let pp_print_sel formatter sel =
  Format.fprintf formatter "<sel \"%s\">" (string_of_sel sel)
