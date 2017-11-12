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
:- module(readtables, []).

:- set_module(class(library)).

:- include('header.pro').



% reader_intern_symbols(ExprS1,ExprS1):- current_prolog_flag(no_symbol_fix,true),!.
reader_intern_symbols(ExprS1,Expr):-
  reading_package(Package),!,
  reader_intern_symbols(Package,ExprS1,Expr),!.


reader_intern_symbols(Package,SymbolName,Symbol):-
   atom(SymbolName),atom_symbol(SymbolName,Package,Symbol),!.
reader_intern_symbols(_Package,Some,Some):- \+ compound(Some),!.
reader_intern_symbols(Package,[S|Some],[SR|SomeR]):- 
  reader_intern_symbols(Package,S,SR),
  reader_intern_symbols(Package,Some,SomeR).
reader_intern_symbols(_Package,Some,Some).


simple_atom_token(SymbolName):- atom_concat('$',_,SymbolName),upcase_atom(SymbolName,SymbolName).
simple_atom_token(SymbolName):- string_upper(SymbolName,UP),string_lower(SymbolName,DOWN),!,UP==DOWN.

atom_symbol(SymbolName,_,Symbol):- simple_atom_token(SymbolName),!,SymbolName=Symbol.
atom_symbol(SymbolName,Package,Symbol):-
  string_upper(SymbolName,SymbolNameU), 
  string_list_concat([SymbolName1|SymbolNameS],":",SymbolNameU),
  atom_symbol_s(SymbolName1,SymbolNameS,Package,Symbol),!.


% :KEYWORD
atom_symbol_s("",[SymbolName],_UPackage,Symbol):- !,atom_symbol_s(SymbolName,[],pkg_kw,Symbol).
% #::SYMBOL
atom_symbol_s("#",["",SymbolName],UPackage,_Symbol):- throw('@TODO *** - READ from #<INPUT CONCATENATED-STREAM #<INPUT STRING-INPUT-STREAM> #<IO TERMINAL-STREAM>>: token ":BAR" after #: should contain no colon'(atom_symbol_s("#",["",SymbolName],UPackage))).  
% #:SYMBOL
atom_symbol_s("#",[SymbolName],_UPackage,Symbol):- cl_make_symbol(SymbolName,Symbol).
% SYMBOL
atom_symbol_s(SymbolName,[],Package,Symbol):- intern_symbol(SymbolName,Package,Symbol,_).
% PACKAGE:SYMBOL
atom_symbol_s(PName,   [SymbolName],_UPackage,Symbol):- find_package_or_die(PName,Package),atom_symbol_public(SymbolName,Package,Symbol).
% PACKAGE::SYMBOL
atom_symbol_s(PName,   [SymbolName],_UPackage,Symbol):- find_package_or_die(PName,Package),atom_symbol_exists(SymbolName,Package,Symbol).

atom_symbol_exists(SymbolName,Package, Symbol):- package_find_symbol(SymbolName,Package,Symbol,_IntExt),!.
atom_symbol_exists(SymbolName,Package,_Symbol):- throw('symbol_not_exists'(SymbolName,Package)).

atom_symbol_public(SymbolName,Package, Symbol):- package_find_symbol(SymbolName,Package,Symbol,IntExt)-> IntExt\==kw_internal,!.
atom_symbol_public(SymbolName,Package,_Symbol):- throw('symbol_not_exported'(SymbolName,Package)).


string_list_concat(StrS,Sep,String):- atomic_list_concat(L,Sep,String),atomics_to_strings(L,StrS).
atomics_to_strings([A|L],[S|StrS]):-atom_string(A,S),!,atomics_to_strings(L,StrS).
atomics_to_strings([],[]).

atom_symbol_test(SymbolName,Symbol):- reading_package(Package),atom_symbol(SymbolName,Package,Symbol),!.


:- fixup_exports.

end_of_file.
