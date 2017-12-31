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
 * The program is a *HUGE* common-lisp compiler/interpreter. It is written for YAP/SWI-Prolog .
 *
 *******************************************************************/
:- module(symbol, []).
:- set_module(class(library)).
:- include('header').

wl:type_checked(cl_symbol_name(claz_symbol,claz_string)).
cl_symbol_name(Symbol,Str):- pl_symbol_name(Symbol,Name),to_lisp_string(Name,Str).
pl_symbol_name(Symbol,Name):- package_external_symbols(pkg_kw,Name,Symbol)->true;get_opv(Symbol,name,Name).
cl_symbol_package(Symbol,Package):- is_keywordp(Symbol)->Package=pkg_kw;get_opv(Symbol,package,Package).
cl_symbol_value(Symbol,Value):- is_keywordp(Symbol)->Symbol=Value;do_or_die(get_opv(Symbol,value,Value)).
cl_symbol_function(Symbol,Function):- do_or_die(get_opv(Symbol,function,Function)),!.
do_or_die(G):- G->true;throw(do_or_die(G)).

wl:interned_eval(("`ext:set-symbol-function")).
f_ext_set_symbol_function(Symbol,Function):- 
  as_funcallable(Symbol,Function,Funcallable),
  set_opv(Symbol,function,Funcallable),
  set_opv(Symbol,compile_as,kw_function).

symbol_prefix_and_atom(Sym,FunPkg,Name):- 
   pl_symbol_name(Sym,SName),
   downcase_atom(SName,Name),
   atomic_list_concat([FunPkg,Name],'_',Sym).

wl:interned_eval(("`sys:set-symbol-value")).
f_sys_set_symbol_value(Var,Val,Val):- set_opv(Var,value,Val).
f_sys_set_symbol_value(Var,Val):- set_opv(Var,value,Val).
cl_set(Var,Val,Val):- rtrace(set_opv(Var,value,Val)).


/*
 deduced now
cl_boundp(Symbol,TF):-  t_or_nil(is_boundp(Symbol),TF).
cl_constantp(Symbol,TF):- t_or_nil(is_constantp(Symbol),TF).
cl_fboundp(Symbol,TF):-  t_or_nil(is_fboundp(Symbol),TF).
cl_keywordp(Symbol,TF):-  t_or_nil(is_keywordp(Symbol),TF).
cl_symbolp(Symbol,TF):-  t_or_nil(is_symbolp(Symbol),TF).
*/

cl_gensym(Symbol):- cl_gensym("G",Symbol).
cl_gensym(Integer,Symbol):- integer(Integer),!,atom_concat('G',Integer,SymbolName),cl_make_symbol(SymbolName,Symbol).
cl_gensym(Name,Symbol):- to_prolog_string(Name,String), gensym(String,SymbolName),cl_make_symbol(SymbolName,Symbol).

cl_gentemp(Symbol):- cl_gentemp("T",Symbol).
cl_gentemp(Name,Symbol):- reading_package(Package),cl_gentemp(Name,Package,Symbol).
cl_gentemp(Name,Package,Symbol):- to_prolog_string(Name,String), gensym(String,SymbolName),cl_intern(SymbolName,Package,Symbol).


is_boundp(Symbol):- is_keywordp(Symbol);get_opv(Symbol,value,_).
is_constantp(Object):- is_self_evaluationing_const(Object);get_opv(Object,defined_as,defconstant).
is_fboundp(Symbol):- get_opv(Symbol,function,_).
is_keywordp(Symbol):- package:package_external_symbols(pkg_kw,_,Symbol).
is_symbolp(Symbol):- is_keywordp(Symbol);get_opv(Symbol,classof,claz_symbol).

%is_keywordp(Symbol):- atom(Symbol),sanity((always(\+ atom_concat_or_rtrace(':',_,Symbol)))),!,fail.



cl_find_symbol(String,Result):- reading_package(Package)->cl_find_symbol(String,Package,Result).
cl_find_symbol(String,Pack,Result):-  find_package_or_die(Pack,Package),
  package_find_symbol(String,Package,Symbol,IntExt),cl_values_list([Symbol,IntExt],Result),!.
cl_find_symbol(_Var,_P,Result):- cl_values_list([[],[]],Result).


cl_intern(Symbol,Result):- reading_package(Package),cl_intern(Symbol,Package,Result).
% cl_intern(Symbol,Package,Result):- \+ is_keywordp(Symbol),is_symbolp(Symbol),!,cl_intern_symbol(Symbol,Package,Result).
cl_intern(Name,Pack,Result):-
  find_package_or_die(Pack,Package),
  text_to_string(Name,String),
  intern_symbol(String,Package,Symbol,IntExt),
  cl_values_list([Symbol,IntExt],Result),!.


intern_symbol(String,Package,Symbol,IntExt):- package_find_symbol(String,Package,Symbol,IntExt),!.
intern_symbol(String,Package,Symbol,IntExt):- 
   make_fresh_internal_symbol(Package,String,Symbol),
   always((package_find_symbol(String,Package,FoundSymbol,IntExt),FoundSymbol==Symbol)).


cl_unintern(Symbol,t):- 
   cl_symbol_package(Symbol,Package),
   (Package\==[]-> package_unintern_symbol(Package,Symbol) ; true),
   set_opv(Symbol,package,[]),
   delete_obj(Symbol).



cl_unintern(String,Package,Symbol,IntExt):- package_find_symbol(String,Package,Symbol,IntExt),!.
unintern_symbol(String,Package,Symbol,IntExt):- 
   make_fresh_uninternal_symbol(Package,String,Symbol),
   always((package_find_symbol(String,Package,FoundSymbol,IntExt),FoundSymbol==Symbol)).


(wl:init_args(x,make_symbol)).

cl_make_symbol(String,Symbol):- to_prolog_string_if_needed(String,PlString),!,cl_make_symbol(PlString,Symbol).
cl_make_symbol(SymbolName,Symbol):- 
   prologcase_name(SymbolName,ProposedName),
   gensym(ProposedName,Symbol),
   create_symbol(SymbolName,[],Symbol).

cl_make_symbol(String,Package,Symbol):- to_prolog_string_if_needed(String,PlString),!,cl_make_symbol(PlString,Package,Symbol).
cl_make_symbol(SymbolName,Package,Symbol):- 
   prologcase_name(SymbolName,ProposedName),
   gensym(ProposedName,Symbol),                
   create_symbol(SymbolName,Package,Symbol).


create_symbol(String,pkg_kw,Symbol):-!,create_keyword(String,Symbol).
create_symbol(String,Package,Symbol):- to_prolog_string_if_needed(String,PlString),!,create_symbol(PlString,Package,Symbol).
create_symbol(String,Package,Symbol):-
   text_to_string(String,Name),
   set_opv(Symbol,classof,claz_symbol),
   set_opv(Symbol,name,Name),
   set_opv(Symbol,package,Package),!.

create_keyword(Name,Symbol):- atom_concat_or_rtrace(':',Make,Name),!,create_keyword(Make,Symbol).
create_keyword(Name,Symbol):- string_upper(Name,String),
   prologcase_name(String,Lower),
   atom_concat_or_rtrace('kw_',Lower,Symbol),
   assert_lsp(package:package_external_symbols(pkg_kw,String,Symbol)).

to_kw(Name0,Name):-atom(Name0),atom_concat('kw_',_,Name0),!,Name0=Name.
to_kw(Name,Combined):- pl_symbol_name(Name,Str),create_keyword(Str,Combined).


print_symbol(Symbol):- 
   writing_package(Package),
   ((print_symbol_at(Symbol,Package))),!.
print_symbol(Symbol):-write(Symbol).
 
print_symbol_at(Symbol,PrintP):- 
  cl_symbol_package(Symbol,SPackage),!,
  print_symbol_from(Symbol,PrintP,SPackage),!.

print_symbol_from(Symbol,_PrintP,Pkg):- Pkg == kw_pkg, !, pl_symbol_name(Symbol,Name),write(':'),write(Name).
print_symbol_from(Symbol,PrintP,SPackage):-
  pl_symbol_name(Symbol,Name),
  always(package_find_symbol(Name,SPackage,FoundSymbol,IntExt)),
  always( Symbol\== FoundSymbol -> 
    print_prefixed_symbol(Name,PrintP,SPackage,kw_internal);
    print_prefixed_symbol(Name,PrintP,SPackage,IntExt)).


print_prefixed_symbol(Symbol,_WP,pkg_kw,_):- write(':'),write(Symbol).
print_prefixed_symbol(Symbol,PrintP,SP,_):- SP==PrintP, !,write(Symbol).
print_prefixed_symbol(Symbol,_P,SP,kw_internal):-!, print_package_or_hash(SP),write('::'),write(Symbol).
print_prefixed_symbol(Symbol,PrintP,SP,kw_external):- package_use_list(PrintP,SP),!,write(Symbol).
print_prefixed_symbol(Symbol,_P,SP,kw_external):- !, print_package_or_hash(SP),write(':'),write(Symbol).
print_prefixed_symbol(Symbol,_,SP,_):- print_package_or_hash(SP),write('::'),write(Symbol).





cl_symbol_plist(Symbol,Value):- %assertion(is_symbolp(Symbol)),
   get_opv(Symbol,plist,Value)->true;Value=[].

(wl:init_args(2,get)).
%(get x y &optional d) ==  (getf (symbol-plist x) y &optional d)
cl_get(Symbol,Prop,Optionals,Value):- %assertion(is_symbolp(Symbol)),
  cl_symbol_plist(Symbol,PList),
  nth_param(Optionals,1,[],Default,PresentP),
  (PList==[]-> Value=Default ;
   ((PresentP==t->get_test_pred(cl_eql,Optionals,EqlPred);EqlPred=cl_eql),
   get_plist_value(EqlPred,PList,Prop,Default,Value))).

% (defsetf get (s p &optional d) (v)
%  (if d `(progn ,d (sys:putprop ,s ,v ,p)) `(sys:putprop ,s ,v ,p)))
wl:interned_eval(("`sys:putprop")).
(wl:init_args(3,sys_putprop)).
%(sys:putprop x y) ==  (setf (symbol-plist x) y)
f_sys_putprop(Symbol,Prop,Value,Optionals,Ret):- %assertion(is_symbolp(Symbol)), 
  nth_param(Optionals,1,[],_Default,PresentP),  
  cl_symbol_plist(Symbol,PList),
  (PresentP==t->get_test_pred(cl_eql,Optionals,EqlPred);EqlPred=cl_eql),
  (((set_plist_value_fail_on_missing(EqlPred,_Old,PList,Prop,Value)
      ->true; 
   (Ret=Value, set_opv(Symbol,plist,[Prop,Value|PList]))))).
(wl:init_args(3,sys_put)).
f_sys_put(Symbol,Prop,Value,Optionals,Ret):-
 f_sys_putprop(Symbol,Prop,Value,Optionals,Ret).

nth_param(Optionals,N,Default,Value):- nth1(N,Optionals,Value)->true;Default=Value.
nth_param(Optionals,N,Default,Value,PresentP):- nth1(N,Optionals,Value)->(PresentP=t);(Default=Value,PresentP=[]).

get_plist_value(_TestFn,[PropWas,_|_],_Prop,_Default,_Value):-var(PropWas),!,break.
get_plist_value(_TestFn,PList,_Prop,Default,Default):- \+ is_list(PList),!,break.
get_plist_value(TestFn,[PropWas,Value|PList],Prop,Default,Value):- 
    (apply_as_pred(TestFn,Prop,PropWas)->!;get_plist_value(TestFn,PList,Prop,Default,Value)).
get_plist_value(_TestFn,_PList,_Prop,Default,Default).

cl_getf(PList,Prop,Default,Value):- get_plist_value(cl_eql,PList,Prop,Default,Value).
  
 
set_plist_value_fail_on_missing(EqlPred,Old,[PropWas|CDR],Prop,Value):- apply_as_pred(EqlPred,Prop,PropWas),!,arg(1,CDR,Old),nb_setarg(1,CDR,Value),!.
set_plist_value_fail_on_missing(EqlPred,Old,[_,_,Next|PList],Prop,Value):- !, set_plist_value_fail_on_missing(EqlPred,Old,[Next|PList],Prop,Value).
%set_plist_value_fail_on_missing(EqlPred,Old,[Next|PList],Prop,Value):-




(wl:init_args(2,sys_get_sysprop)).
%(get x y &optional d) ==  (getf (symbol-plist x) y &optional d)
wl:interned_eval(("`sys:get-sysprop")).
f_sys_get_sysprop(Symbol,Prop,Optionals,Value):-!, cl_get(Symbol,Prop,Optionals,Value).

f_sys_get_sysprop(Symbol,Prop,Optionals,Value):- %assertion(is_symbolp(Symbol)),
  nth_param(Optionals,1,[],Default,PresentP),
  (get_opv(Symbol,sysprops,PList) ->  
  ((PList==[]-> Value=Default ;
   ((PresentP==t->get_test_pred(cl_eql,Optionals,EqlPred);EqlPred=cl_eql),
   get_plist_value(EqlPred,PList,Prop,Default,Value))))
   ; Value=Default).

% (defsetf get (s p &optional d) (v)
%  (if d `(progn ,d (sys:putprop ,s ,v ,p)) `(sys:putprop ,s ,v ,p)))
(wl:init_args(3,sys_put_sysprop)).
%(sys::put x y) ==  (setf (symbol-plist x) y)
wl:interned_eval(("#'sys:put-sysprop")).
f_sys_put_sysprop(Symbol,Prop,Value,Optionals,Ret):-!, f_sys_putprop(Symbol,Prop,Value,Optionals,Ret).

f_sys_put_sysprop(Symbol,Prop,Value,Optionals,Ret):- %assertion(is_symbolp(Symbol)),   
  (get_opv(Symbol,sysprops,PList)->true;PList==[]),  
   nth_param(Optionals,1,[],_Default,PresentP),
  (PresentP==t->get_test_pred(cl_eql,Optionals,EqlPred);EqlPred=cl_eql),
  (((set_plist_value_fail_on_missing(EqlPred,_Old,PList,Prop,Value)
      ->true; 
   (Ret=Value, set_opv(Symbol,sysprops,[Prop,Value|PList]))))).



:- fixup_exports.

% :- cl_intern("PUT",pkg_sys,_Symbol).
