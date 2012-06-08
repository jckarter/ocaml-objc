
open Test_case
open Objc

let _ = perform_tests "Objective-C" [
    ("Integer return uses smallest fitting type (XXX assumes 32-bit arch)", fun () ->
      let shifted_ret n = send_ret (nsnumber_of_int64 (Int64.shift_left 1L n)) "longLongValue" [] in
      assert( List.map shifted_ret [28; 29; 30; 31; 32] = [
          `Int (1 lsl 28);
          `Int (1 lsl 29);
          `Nativeint (Nativeint.shift_left 1n 30);
          `Int64 (Int64.shift_left 1L 31);
          `Int64 (Int64.shift_left 1L 32);
      ] );
    );
    ("NSPoint, NSRect, and NSRange", fun () ->
      let pt = NSPoint.make 1.0 2.0 in
      let rc = NSRect.make 1.0 2.0 3.0 4.0 in
      let rn = NSRange.make 10n 20n in
      assert (NSPoint.x pt = 1.0);
      assert (NSPoint.y pt = 2.0);
      assert (NSPoint.x      (NSRect.origin rc) = 1.0);
      assert (NSPoint.y      (NSRect.origin rc) = 2.0);
      assert (NSPoint.width  (NSRect.size rc) = 3.0);
      assert (NSPoint.height (NSRect.size rc) = 4.0);
      assert (NSRange.location rn = 10n);
      assert (NSRange.length   rn = 20n);
    );
    ("NSPoint, NSRect, and NSRange arguments", fun () ->
      let index_set =
        send id_ret
          (clas "NSIndexSet")
          "indexSetWithIndexesInRange:"
          [`NSRange (NSRange.make 1n 2n)]
        in
      let bezier_path =
        send id_ret
          (clas "NSBezierPath")
          "bezierPath"
          []
        in
      let pt = NSPoint.make 3.0 4.0 in
      send void_ret bezier_path "moveToPoint:" [`NSPoint pt];
      assert (send bool_ret index_set "containsIndex:" [`Int 1]);
      assert (send bool_ret index_set "containsIndex:" [`Int 2]);
      assert (not (send bool_ret index_set "containsIndex:" [`Int 3]));
      let pt' = send nspoint_ret bezier_path "currentPoint" [] in
      assert (NSPoint.x pt = NSPoint.x pt');
      assert (NSPoint.y pt = NSPoint.y pt');
    );
]
