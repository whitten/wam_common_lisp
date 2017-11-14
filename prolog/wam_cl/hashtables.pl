/*******************************************************************
 *
 * A Common Lisp compiler/interpretor, written in Prolog
 *
 * (xxxxx.pl)
 *
 *
 * Douglas'' Notes:
 *
 * (c) Douglas Miles, 2017
 *
 * The program is a *HUGE* common-lisp compiler/interpreter. It is written for YAP/SWI-Prolog (YAP 4x faster).
 *
 *******************************************************************/
:- module(hashts, []).

:- set_module(class(library)).

:- include('header.pro').

cl_make_hash_table(X):- X=hashtable{equal_fn:cl_equal,key_values:[]}.

:- fixup_exports.

end_of_file.

