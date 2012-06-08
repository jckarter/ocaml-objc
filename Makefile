
CFLAGS      += -g -Wall -fobjc-exceptions
CFRAMEWORKS += Cocoa
SOURCES      = objc.ml objc.mli objc-prim.m
RESULT       = objc

all: native-code-library byte-code-library

-include OCamlMakefile
