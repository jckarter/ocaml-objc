(************************************************************************
*  test_test.ml
*
*  Created by Joe Groff on 17 Mar 2006.
*  Copyright (c) 2006 Joe Groff. All rights reserved.
************************************************************************)

Test_case.perform_tests "Test"
    ~setup:    (fun () -> Printf.printf "Setting up\n")
    ~teardown: (fun () -> Printf.printf "Tearing down\n")
    [
    	("Assert False should fail", fun () -> assert false);
    	("Assert True should pass",  fun () -> assert true);
	
    	("Assert Raises but doesn't should fail", fun () ->
    		Test_case.assert_raises Not_found (fun () -> ())
    	);
    	("Assert Raises and does should pass", fun () ->
    		Test_case.assert_raises Not_found (fun () -> raise Not_found)
    	);
    ];;

print_string "You shouldn't be reading this\n"