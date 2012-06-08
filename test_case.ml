(************************************************************************
*  test_case.ml
*
*  Created by Joe Groff on 17 Mar 2006.
*  Copyright (c) 2006 Joe Groff. All rights reserved.
************************************************************************)

open Printf

type test_stats = { passed : int; total : int }

let _fun_or_none = function
    | Some fn -> fn
    | None    -> fun () -> ()

let perform_tests ?setup ?teardown test_suite_name tests =
    let setup'    = _fun_or_none setup in
    let teardown' = _fun_or_none teardown in
    let rec actually_perform_tests stats = function
        | [] -> stats
        | (test_name, test) :: other_tests ->
            (try
                setup' ()
            with x ->
                printf "FAILED in test setup!!!\n     -> %s\n" (Printexc.to_string x));

            printf "    %s..." test_name;
            flush stdout;
            let result =
                try
                    test ();
                    print_string "passed\n";
                    flush stdout;
                    1
                with x ->
                    printf "FAILED!!!\n     -> %s\n" (Printexc.to_string x);
                    flush stdout;
                    0
                in
            
            (try
                teardown' ()
            with x ->
                printf "FAILED in test teardown!!!\n     -> %s\n" (Printexc.to_string x);
                flush stdout);
            
            actually_perform_tests
                { passed = stats.passed + result;
                  total  = stats.total + 1 }
                other_tests
        in
    printf "Performing tests for %s:\n" test_suite_name;
    let test_stats = actually_perform_tests { passed = 0; total = 0 } tests in
    let failed = (test_stats.total - test_stats.passed) in
    printf "%d tests performed, %d tests passed, %d tests failed\n"
        test_stats.total
        test_stats.passed
        failed;
    exit failed

let assert_raises expected_x fn =
    try
        fn ();
        assert false
    with x ->
        assert (x = expected_x)
