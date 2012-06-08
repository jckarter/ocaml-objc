(************************************************************************
*  test_case.mli
*
*  Created by Joe Groff on 17 Mar 2006.
*  Copyright (c) 2006 Joe Groff. All rights reserved.
************************************************************************)

type test_stats = { passed : int; total : int }

val perform_tests : ?setup:   (unit -> unit)
                 -> ?teardown:(unit -> unit)
                 -> string -> (string * (unit -> unit)) list -> 'a

val assert_raises : exn -> (unit -> 'a) -> unit
