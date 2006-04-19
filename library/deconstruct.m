%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=4 sw=4 et
%-----------------------------------------------------------------------------%
% Copyright (C) 2002-2006 The University of Melbourne.
% This file may only be copied under the terms of the GNU Library General
% Public License - see the file COPYING.LIB in the Mercury distribution.
%-----------------------------------------------------------------------------%
% 
% File: deconstruct.m.
% Main author: zs.
% Stability: low.
% 
%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- module deconstruct.
:- interface.

:- import_module list.
:- import_module maybe.
:- import_module univ.

%-----------------------------------------------------------------------------%

    % Values of type noncanon_handling are intended to control how
    % predicates that deconstruct terms behave when they find that
    % the term they are about to deconstruct is of a noncanonical type,
    % i.e. of a type in which a single logical value may have more than one
    % concrete representation.
    %
    % The value `do_not_allow' means that in such circumstances the
    % predicate should abort.
    %
    % The value `canonicalize' means that in such circumstances the
    % predicate should return a constant giving the identity of the type,
    % regardless of the actual value of the term.
    %
    % The value `include_details_cc' means that in such circumstances
    % the predicate should proceed as if the term were of a canonical type.
    % Use of this option requires a committed choice context.

:- type noncanon_handling
    --->    do_not_allow
    ;       canonicalize
    ;       include_details_cc.

:- inst do_not_allow ---> do_not_allow.
:- inst canonicalize ---> canonicalize.
:- inst include_details_cc ---> include_details_cc.
:- inst canonicalize_or_do_not_allow
    --->    do_not_allow
    ;       canonicalize.

    % functor, argument and deconstruct and their variants take any type
    % (including univ), and return representation information for that type.
    %
    % The string representation of the functor that these predicates
    % return is:
    %
    %   - for user defined types with standard equality, the functor
    %     that is given in the type definition. For lists, this means
    %     the functors [|]/2 and []/0 are used, even if the list uses
    %     the [....] shorthand.
    %   - for user-defined types with user-defined equality, the
    %     functor will be of the form <<module.type/arity>>, except
    %     with include_details_cc, in which case the type will be
    %     handled as if it had standard equality.
    %   - for integers, the string is a base 10 number;
    %     positive integers have no sign.
    %   - for floats, the string is a floating point, base 10 number;
    %     positive floating point numbers have no sign.
    %   - for strings, the string, inside double quotation marks
    %   - for characters, the character inside single quotation marks
    %   - for predicates, the string <<predicate>>, and for functions,
    %     the string <<function>>, except with include_details_cc,
    %     in which case it will be the predicate or function name.
    %     (The predicate or function name will be artificial for
    %     predicate and function values created by lambda expressions.)
    %   - for tuples, the string {}.
    %   - for arrays, the string <<array>>.
    %
    % The arity that these predicates return is:
    %
    %   - for user defined types with standard equality, the arity
    %     of the functor.
    %   - for user defined types with user-defined equality, zero,
    %     except with include_details_cc, in which case the type
    %     will be handled as if it had standard equality.
    %   - for integers, zero.
    %   - for floats, zero.
    %   - for strings, zero.
    %   - for characters, zero.
    %   - for predicates and functions, zero, except with
    %     include_details_cc, in which case it will be the number of
    %     arguments hidden in the closure.
    %   - for tuples, the number of elements in the tuple.
    %   - for arrays, the number of elements in the array.
    %
    % Note that in the current University of Melbourne implementation,
    % the implementations of these predicates depart from the above
    % specification in that with --high-level-code, they do not
    % deconstruct predicate- and function-valued terms even with
    % include_details_cc; instead, they return <<predicate>> or
    % <<function>> (in both cases with arity zero) as appropriate.

    % functor(Data, NonCanon, Functor, Arity)
    %
    % Given a data item (Data), binds Functor to a string representation
    % of the functor and Arity to the arity of this data item.
    %
:- pred functor(T, noncanon_handling, string, int).
:- mode functor(in, in(do_not_allow), out, out) is det.
:- mode functor(in, in(canonicalize), out, out) is det.
:- mode functor(in, in(include_details_cc), out, out) is cc_multi.
:- mode functor(in, in, out, out) is cc_multi.

    % arg(Data, NonCanon, Index, Argument)
    %
    % Given a data item (Data) and an argument index (Index), starting
    % at 0 for the first argument, binds Argument to that argument of
    % the functor of the data item. If the argument index is out of range
    % -- that is, greater than or equal to the arity of the functor or
    % lower than 0 -- then the call fails.
    %
    % Note that this predicate only returns an answer when NonCanon is
    % do_not_allow or canonicalize.  If you need the include_details_cc
    % behaviour use deconstruct.arg_cc/3.
    %
:- some [ArgT] pred arg(T, noncanon_handling, int, ArgT).
:- mode arg(in, in(do_not_allow), in, out) is semidet.
:- mode arg(in, in(canonicalize), in, out) is semidet.
:- mode arg(in, in(canonicalize_or_do_not_allow), in, out) is semidet.

:- type maybe_arg
    --->    some [T] arg(T)
    ;       no_arg.

    % arg_cc/3 is similar to arg/4, except that it handles arguments with
    % non-canonical types.  The possible non-existence of an argument is
    % encoded using a maybe type.
    %
:- pred arg_cc(T::in, int::in, maybe_arg::out) is cc_multi.

    % named_arg(Data, NonCanon, Name, Argument)
    %
    % Same as arg/4, except the chosen argument is specified by giving
    % its name rather than its position. If Data has no argument with that
    % name, named_arg fails.
    %
:- some [ArgT] pred named_arg(T, noncanon_handling, string, ArgT).
:- mode named_arg(in, in(do_not_allow), in, out) is semidet.
:- mode named_arg(in, in(canonicalize), in, out) is semidet.
:- mode named_arg(in, in(canonicalize_or_do_not_allow), in, out) is semidet.

    % named_arg_cc/3 is similar to named_arg/4, except that it handles
    % arguments with non-canonical types.
    %
:- pred named_arg_cc(T::in, string::in, maybe_arg::out) is cc_multi.

    % det_arg(Data, NonCanon, Index, Argument)
    %
    % Same as arg/4, except that for cases where arg/4 would fail,
    % det_arg/4 will abort.
    %
:- some [ArgT] pred det_arg(T, noncanon_handling, int, ArgT).
:- mode det_arg(in, in(do_not_allow), in, out) is det.
:- mode det_arg(in, in(canonicalize), in, out) is det.
:- mode det_arg(in, in(include_details_cc), in, out) is cc_multi.
:- mode det_arg(in, in, in, out) is cc_multi.

    % det_named_arg(Data, NonCanon, Name, Argument)
    %
    % Same as named_arg/4, except that for cases where named_arg/4 would fail,
    % det_named_arg/4 will abort.
    %
:- some [ArgT] pred det_named_arg(T, noncanon_handling, string, ArgT).
:- mode det_named_arg(in, in(do_not_allow), in, out) is det.
:- mode det_named_arg(in, in(canonicalize), in, out) is det.
:- mode det_named_arg(in, in(include_details_cc), in, out) is cc_multi.
:- mode det_named_arg(in, in, in, out) is cc_multi.

    % deconstruct(Data, NonCanon, Functor, Arity, Arguments)
    %
    % Given a data item (Data), binds Functor to a string representation
    % of the functor, Arity to the arity of this data item, and Arguments
    % to a list of arguments of the functor. The arguments in the list
    % are each of type univ.
    %
    % The cost of calling deconstruct depends greatly on how many arguments
    % Data has. If Data is an array, then each element of the array is
    % considered one of its arguments. Therefore calling deconstruct
    % on large arrays can take a very large amount of memory and a very
    % long time. If you call deconstruct in a situation in which you may
    % pass it a large array, you should probably use limited_deconstruct
    % instead.
    %
:- pred deconstruct(T, noncanon_handling, string, int, list(univ)).
:- mode deconstruct(in, in(do_not_allow), out, out, out) is det.
:- mode deconstruct(in, in(canonicalize), out, out, out) is det.
:- mode deconstruct(in, in(include_details_cc), out, out, out) is cc_multi.
:- mode deconstruct(in, in, out, out, out) is cc_multi.

    % limited_deconstruct(Data, NonCanon, MaxArity,
    %   Functor, Arity, Arguments)
    %
    % limited_deconstruct works like deconstruct, but if the arity of T is
    % greater than MaxArity, limited_deconstruct fails. This is useful in
    % avoiding bad performance in cases where Data may be a large array.
    %
    % Note that this predicate only returns an answer when NonCanon is
    % do_not_allow or canonicalize.  If you need the include_details_cc
    % behaviour use deconstruct.limited_deconstruct_cc/3.
    %
:- pred limited_deconstruct(T, noncanon_handling, int, string, int,
    list(univ)).
:- mode limited_deconstruct(in, in(do_not_allow), in, out, out, out)
    is semidet.
:- mode limited_deconstruct(in, in(canonicalize), in, out, out, out)
    is semidet.

:- pred limited_deconstruct_cc(T::in, int::in,
    maybe({string, int, list(univ)})::out) is cc_multi.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- import_module int.
:- import_module require.
:- import_module rtti_implementation.
:- import_module string.

:- pragma foreign_decl("C", "

#include ""mercury_deconstruct.h""
#include ""mercury_deconstruct_macros.h""

").

%-----------------------------------------------------------------------------%

% XXX The no-inline pragmas are necessary because when it inlines a predicate
% defined by foreign_procs, the compiler does not preserve the names of the
% typeinfo variables. Thus these foreign_proc's references to TypeInfo_for_T
% will refer to an undefined variable.

:- pragma no_inline(functor/4).
:- pragma no_inline(arg/4).
:- pragma no_inline(named_arg/4).
:- pragma no_inline(deconstruct/5).
:- pragma no_inline(limited_deconstruct/6).

%-----------------------------------------------------------------------------%

functor(Term, NonCanon, Functor, Arity) :-
    (
        NonCanon = do_not_allow,
        functor_dna(Term, Functor, Arity)
    ;
        NonCanon = canonicalize,
        functor_can(Term, Functor, Arity)
    ;
        NonCanon = include_details_cc,
        functor_idcc(Term, Functor, Arity)
    ).

arg(Term, NonCanon, Index, Argument) :-
    (
        NonCanon = do_not_allow,
        univ_arg_dna(Term, Index, Univ)
    ;
        NonCanon = canonicalize,
        univ_arg_can(Term, Index, Univ)
    ;
        NonCanon = include_details_cc,
        error("deconstruct.arg called with include_details_cc")
    ),
    Argument = univ_value(Univ).

arg_cc(Term, Index, MaybeArg) :-
    univ_arg_idcc(Term, Index, dummy_univ, Univ, Success),
    ( Success \= 0 ->
        MaybeArg = 'new arg'(univ_value(Univ))
    ;
        MaybeArg = no_arg
    ).

named_arg(Term, NonCanon, Name, Argument) :-
    (
        NonCanon = do_not_allow,
        univ_named_arg_dna(Term, Name, Univ)
    ;
        NonCanon = canonicalize,
        univ_named_arg_can(Term, Name, Univ)
    ;
        NonCanon = include_details_cc,
        error("deconstruct.named_arg called with include_details_cc")
    ),
    Argument = univ_value(Univ).

named_arg_cc(Term, Name, MaybeArg) :-
    univ_named_arg_idcc(Term, Name, dummy_univ, Univ, Success),
    ( Success \= 0 ->
        MaybeArg = 'new arg'(univ_value(Univ))
    ;
        MaybeArg = no_arg
    ).

    % This is a dummy value of type `univ'. It is used only to ensure that
    % the C interface procedure univ_named_arg_idcc doesn't return an
    % uninitialized (or otherwise bogus) univ value.
    %
:- func dummy_univ = univ.

dummy_univ = univ(0).

det_arg(Term, NonCanon, Index, Argument) :-
    (
        NonCanon = do_not_allow,
        ( univ_arg_dna(Term, Index, Univ0) ->
            Univ = Univ0
        ;
            error("det_arg: argument number out of range")
        )
    ;
        NonCanon = canonicalize,
        ( univ_arg_can(Term, Index, Univ0) ->
            Univ = Univ0
        ;
            error("det_arg: argument number out of range")
        )
    ;
        NonCanon = include_details_cc,
        univ_arg_idcc(Term, Index, dummy_univ, Univ0, Success),
        ( Success \= 0 ->
            Univ = Univ0
        ;
            error("det_arg: argument number out of range")
        )
    ),
    Argument = univ_value(Univ).

det_named_arg(Term, NonCanon, Name, Argument) :-
    (
        (
            NonCanon = do_not_allow,
            univ_named_arg_dna(Term, Name, Univ)
        ;
            NonCanon = canonicalize,
            univ_named_arg_can(Term, Name, Univ)
        ;
            NonCanon = include_details_cc,
            univ_named_arg_idcc(Term, Name, dummy_univ, Univ0, Success),
            ( Success \= 0 ->
                Univ = Univ0
            ;
                error("det_named_arg: no argument with that name")
            )
        )
    ->
        Argument = univ_value(Univ)
    ;
        error("det_named_arg: no argument with that name")
    ).

deconstruct(Term, NonCanon, Functor, Arity, Arguments) :-
    (
        NonCanon = do_not_allow,
        deconstruct_dna(Term, Functor, Arity, Arguments)
    ;
        NonCanon = canonicalize,
        deconstruct_can(Term, Functor, Arity, Arguments)
    ;
        NonCanon = include_details_cc,
        deconstruct_idcc(Term, Functor, Arity, Arguments)
    ).

limited_deconstruct(Term, NonCanon, MaxArity, Functor, Arity, Arguments) :-
    (
        NonCanon = do_not_allow,
        limited_deconstruct_dna(Term, MaxArity, Functor, Arity, Arguments)
    ;
        NonCanon = canonicalize,
        limited_deconstruct_can(Term, MaxArity, Functor, Arity, Arguments)
    ;
        NonCanon = include_details_cc,
        error("limited_deconstruct called with include_details_cc")
    ).

limited_deconstruct_cc(Term, MaxArity, MaybeResult) :-
    limited_deconstruct_idcc(Term, MaxArity, Functor, Arity, Arguments),
    ( Arity =< MaxArity ->
        MaybeResult = yes({Functor, Arity, Arguments})
    ;
        MaybeResult = no
    ).

%-----------------------------------------------------------------------------%

:- pred functor_dna(T::in, string::out, int::out) is det.
:- pred functor_can(T::in, string::out, int::out) is det.
:- pred functor_idcc(T::in, string::out, int::out) is cc_multi.

:- pragma foreign_proc("C",
    functor_dna(Term::in, Functor::out, Arity::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define NONCANON                MR_NONCANON_ABORT
#include ""mercury_ml_functor_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  NONCANON
}").

:- pragma foreign_proc("C",
    functor_can(Term::in, Functor::out, Arity::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define NONCANON                MR_NONCANON_ALLOW
#include ""mercury_ml_functor_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  NONCANON
}").

:- pragma foreign_proc("C",
    functor_idcc(Term::in, Functor::out, Arity::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define NONCANON                MR_NONCANON_CC
#include ""mercury_ml_functor_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  NONCANON
}").

functor_dna(Term::in, Functor::out, Arity::out) :-
    rtti_implementation.deconstruct(Term,
        do_not_allow, Functor, Arity, _Arguments).
functor_can(Term::in, Functor::out, Arity::out) :-
    rtti_implementation.deconstruct(Term,
        canonicalize, Functor, Arity, _Arguments).
functor_idcc(Term::in, Functor::out, Arity::out) :-
    rtti_implementation.deconstruct(Term,
        include_details_cc, Functor, Arity, _Arguments).

%-----------------------------------------------------------------------------%

% XXX These predicates return univs instead of existentially typed arguments
% in order to work around the typechecking bug reported on 30 Jan, 2002
% to the mercury-bugs mailing list, and which has sourceforge bug id 512581:
% currently we don't support implementations in multiple languages
% for procedures with existentially typed arguments.

:- pred univ_arg_dna(T::in, int::in, univ::out) is semidet.
:- pred univ_arg_can(T::in, int::in, univ::out) is semidet.

    % univ_arg_idcc(Term, N, DummyUniv, Argument, Success):
    %
    % Attempt to extract the Nth field of (the current representation of) Term.
    % If there is such a field, return Success=1 and return the field in
    % Argument. If there is not, return Success=0 and Argument=DummyUniv.
    %
:- pred univ_arg_idcc(T::in, int::in, univ::in, univ::out, int::out)
    is cc_multi.

:- pred univ_named_arg_dna(T::in, string::in, univ::out) is semidet.
:- pred univ_named_arg_can(T::in, string::in, univ::out) is semidet.

    % univ_named_arg_idcc(Term, Name, DummyUniv, Univ, Success):
    %
    % Attempt to extract the field of (the current representation of) Term
    % specified by Name. If there is such a field, return Success=1 and return
    % the field in Univ. If there is not, return Success=0 and Univ=DummyUniv.
    %
:- pred univ_named_arg_idcc(T::in, string::in, univ::in, univ::out, int::out)
    is cc_multi.

:- pragma foreign_proc("C",
    univ_arg_dna(Term::in, Index::in, Argument::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define SELECTOR_ARG            Index
#define SELECTED_ARG            Argument
#define SELECTED_TYPE_INFO      TypeInfo_for_ArgT
#define NONCANON                MR_NONCANON_ABORT
#define SAVE_SUCCESS
#include ""mercury_ml_arg_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  SELECTOR_ARG
#undef  SELECTED_ARG
#undef  SELECTED_TYPE_INFO
#undef  NONCANON
#undef  SAVE_SUCCESS
}").

:- pragma foreign_proc("C",
    univ_arg_can(Term::in, Index::in, Argument::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define SELECTOR_ARG            Index
#define SELECTED_ARG            Argument
#define SELECTED_TYPE_INFO      TypeInfo_for_ArgT
#define NONCANON                MR_NONCANON_ALLOW
#define SAVE_SUCCESS
#include ""mercury_ml_arg_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  SELECTOR_ARG
#undef  SELECTED_ARG
#undef  SELECTED_TYPE_INFO
#undef  NONCANON
#undef  SAVE_SUCCESS
}").

:- pragma foreign_proc("C",
    univ_arg_idcc(Term::in, Index::in, DummyUniv::in, Argument::out,
        Success::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
    #define TYPEINFO_ARG        TypeInfo_for_T
    #define TERM_ARG            Term
    #define SELECTOR_ARG        Index
    #define SELECTED_ARG        Argument
    #define SELECTED_TYPE_INFO  TypeInfo_for_ArgT
    #define NONCANON            MR_NONCANON_CC
    #include ""mercury_ml_arg_body.h""
    #undef  TYPEINFO_ARG
    #undef  TERM_ARG
    #undef  SELECTOR_ARG
    #undef  SELECTED_ARG
    #undef  SELECTED_TYPE_INFO
    #undef  NONCANON

    if (success) {
        Success = 1;
    } else {
        Success = 0;
        Argument = DummyUniv;
    }
}").

:- pragma foreign_proc("C",
    univ_named_arg_dna(Term::in, Name::in, Argument::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define SELECTOR_ARG            (MR_ConstString) Name
#define SELECTED_ARG            Argument
#define SELECTED_TYPE_INFO      TypeInfo_for_ArgT
#define NONCANON                MR_NONCANON_ABORT
#define SELECT_BY_NAME
#define SAVE_SUCCESS
#include ""mercury_ml_arg_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  SELECTOR_ARG
#undef  SELECTED_ARG
#undef  SELECTED_TYPE_INFO
#undef  NONCANON
#undef  SELECT_BY_NAME
#undef  SAVE_SUCCESS
}").

:- pragma foreign_proc("C",
    univ_named_arg_can(Term::in, Name::in, Argument::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define SELECTOR_ARG            (MR_ConstString) Name
#define SELECTED_ARG            Argument
#define SELECTED_TYPE_INFO      TypeInfo_for_ArgT
#define NONCANON                MR_NONCANON_ALLOW
#define SELECT_BY_NAME
#define SAVE_SUCCESS
#include ""mercury_ml_arg_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  SELECTOR_ARG
#undef  SELECTED_ARG
#undef  SELECTED_TYPE_INFO
#undef  NONCANON
#undef  SELECT_BY_NAME
#undef  SAVE_SUCCESS
}").

:- pragma foreign_proc("C",
    univ_named_arg_idcc(Term::in, Name::in, DummyUniv::in,
        Argument::out, Success::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define SELECTOR_ARG            (MR_ConstString) Name
#define SELECTED_ARG            Argument
#define SELECTED_TYPE_INFO      TypeInfo_for_ArgT
#define NONCANON                MR_NONCANON_CC
#define SELECT_BY_NAME
#include ""mercury_ml_arg_body.h""
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  SELECTOR_ARG
#undef  SELECTED_ARG
#undef  SELECTED_TYPE_INFO
#undef  NONCANON
#undef  SELECT_BY_NAME

    if (success) {
        Success = 1;
    } else {
        Success = 0;
        Argument = DummyUniv;
    }

}").

% XXX These Mercury implementations are all inefficient, since they
% unnecessarily construct the list of univs for all the arguments, rather than
% just constructing one univ for the argument selected.

univ_arg_dna(Term::in, Index::in, Arg::out) :-
    rtti_implementation.deconstruct(Term, do_not_allow,
        _Functor, _Arity, Arguments),
    list.index0(Arguments, Index, Arg).
univ_arg_can(Term::in, Index::in, Arg::out) :-
    rtti_implementation.deconstruct(Term, canonicalize,
        _Functor, _Arity, Arguments),
    list.index0(Arguments, Index, Arg).
univ_arg_idcc(Term::in, Index::in, DummyUniv::in, Argument::out,
        Success::out) :-
    rtti_implementation.deconstruct(Term, include_details_cc,
        _Functor, _Arity, Arguments),
    ( list.index0(Arguments, Index, Arg) ->
        Argument = Arg,
        Success = 1
    ;
        Argument = DummyUniv,
        Success = 0
    ).

%-----------------------------------------------------------------------------%

:- pred deconstruct_dna(T::in, string::out, int::out, list(univ)::out) is det.
:- pred deconstruct_can(T::in, string::out, int::out, list(univ)::out) is det.
:- pred deconstruct_idcc(T::in, string::out, int::out, list(univ)::out)
    is cc_multi.

:- pred limited_deconstruct_dna(T::in, int::in,
    string::out, int::out, list(univ)::out) is semidet.
:- pred limited_deconstruct_can(T::in, int::in,
    string::out, int::out, list(univ)::out) is semidet.
:- pred limited_deconstruct_idcc(T::in, int::in,
    string::out, int::out, list(univ)::out) is cc_multi.

:- pragma foreign_proc("C",
    deconstruct_dna(Term::in, Functor::out, Arity::out, Arguments::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define EXPAND_INFO_TYPE        MR_Expand_Functor_Args_Info
#define EXPAND_INFO_CALL        MR_expand_functor_args
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define ARGUMENTS_ARG           Arguments
#define NONCANON                MR_NONCANON_ABORT
#include ""mercury_ml_deconstruct_body.h""
#undef  EXPAND_INFO_TYPE
#undef  EXPAND_INFO_CALL
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  ARGUMENTS_ARG
#undef  NONCANON
}").

:- pragma foreign_proc("C",
    deconstruct_can(Term::in, Functor::out, Arity::out, Arguments::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define EXPAND_INFO_TYPE        MR_Expand_Functor_Args_Info
#define EXPAND_INFO_CALL        MR_expand_functor_args
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define ARGUMENTS_ARG           Arguments
#define NONCANON                MR_NONCANON_ALLOW
#include ""mercury_ml_deconstruct_body.h""
#undef  EXPAND_INFO_TYPE
#undef  EXPAND_INFO_CALL
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  ARGUMENTS_ARG
#undef  NONCANON
}").

:- pragma foreign_proc("C",
    deconstruct_idcc(Term::in, Functor::out, Arity::out, Arguments::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define EXPAND_INFO_TYPE        MR_Expand_Functor_Args_Info
#define EXPAND_INFO_CALL        MR_expand_functor_args
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define ARGUMENTS_ARG           Arguments
#define NONCANON                MR_NONCANON_CC
#include ""mercury_ml_deconstruct_body.h""
#undef  EXPAND_INFO_TYPE
#undef  EXPAND_INFO_CALL
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  ARGUMENTS_ARG
#undef  NONCANON
}").

:- pragma foreign_proc("C",
    limited_deconstruct_dna(Term::in, MaxArity::in,
        Functor::out, Arity::out, Arguments::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define EXPAND_INFO_TYPE        MR_Expand_Functor_Args_Limit_Info
#define EXPAND_INFO_CALL        MR_expand_functor_args_limit
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define MAX_ARITY_ARG           MaxArity
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define ARGUMENTS_ARG           Arguments
#define NONCANON                MR_NONCANON_ABORT
#define SAVE_SUCCESS
#include ""mercury_ml_deconstruct_body.h""
#undef  EXPAND_INFO_TYPE
#undef  EXPAND_INFO_CALL
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  MAX_ARITY_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  ARGUMENTS_ARG
#undef  NONCANON
#undef  SAVE_SUCCESS
}").

:- pragma foreign_proc("C",
    limited_deconstruct_can(Term::in, MaxArity::in,
        Functor::out, Arity::out, Arguments::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
#define EXPAND_INFO_TYPE        MR_Expand_Functor_Args_Limit_Info
#define EXPAND_INFO_CALL        MR_expand_functor_args_limit
#define TYPEINFO_ARG            TypeInfo_for_T
#define TERM_ARG                Term
#define MAX_ARITY_ARG           MaxArity
#define FUNCTOR_ARG             Functor
#define ARITY_ARG               Arity
#define ARGUMENTS_ARG           Arguments
#define NONCANON                MR_NONCANON_ALLOW
#define SAVE_SUCCESS
#include ""mercury_ml_deconstruct_body.h""
#undef  EXPAND_INFO_TYPE
#undef  EXPAND_INFO_CALL
#undef  TYPEINFO_ARG
#undef  TERM_ARG
#undef  MAX_ARITY_ARG
#undef  FUNCTOR_ARG
#undef  ARITY_ARG
#undef  ARGUMENTS_ARG
#undef  NONCANON
#undef  SAVE_SUCCESS
}").

:- pragma foreign_proc("C",
    limited_deconstruct_idcc(Term::in, MaxArity::in, Functor::out,
        Arity::out, Arguments::out),
    [will_not_call_mercury, thread_safe, promise_pure],
"{
    #define EXPAND_INFO_TYPE    MR_Expand_Functor_Args_Limit_Info
    #define EXPAND_INFO_CALL    MR_expand_functor_args_limit
    #define TYPEINFO_ARG        TypeInfo_for_T
    #define TERM_ARG            Term
    #define MAX_ARITY_ARG       MaxArity
    #define FUNCTOR_ARG         Functor
    #define ARITY_ARG           Arity
    #define ARGUMENTS_ARG       Arguments
    #define NONCANON            MR_NONCANON_CC
    #include ""mercury_ml_deconstruct_body.h""
    #undef  EXPAND_INFO_TYPE
    #undef  EXPAND_INFO_CALL
    #undef  TYPEINFO_ARG
    #undef  TERM_ARG
    #undef  MAX_ARITY_ARG
    #undef  FUNCTOR_ARG
    #undef  ARITY_ARG
    #undef  ARGUMENTS_ARG
    #undef  NONCANON

    if (!success) {
        /*
        ** Fill in some dummy values, to ensure that we don't try to return
        ** uninitialized memory to Mercury. It doesn't matter what we put here,
        ** except that we must have Arity > MaxArity. The casts cast away
        ** const.
        */

        Arity = MaxArity + 1;
        Functor = (MR_String) (MR_Integer) """";
        Arguments = MR_list_empty();
    }
}").

deconstruct_dna(Term::in, Functor::out, Arity::out, Arguments::out) :-
    rtti_implementation.deconstruct(Term, do_not_allow,
        Functor, Arity, Arguments).
deconstruct_can(Term::in, Functor::out, Arity::out, Arguments::out) :-
    rtti_implementation.deconstruct(Term, canonicalize,
        Functor, Arity, Arguments).
deconstruct_idcc(Term::in, Functor::out, Arity::out, Arguments::out) :-
    rtti_implementation.deconstruct(Term, include_details_cc,
        Functor, Arity, Arguments).

    % XXX The Mercury implementations of all of these limited_* procedures
    % are inefficient -- they construct Functor and Arguments even in the case
    % when Arity > MaxArity.
limited_deconstruct_dna(Term::in, MaxArity::in,
        Functor::out, Arity::out, Arguments::out) :-
    rtti_implementation.deconstruct(Term, do_not_allow,
        Functor, Arity, Arguments),
    Arity =< MaxArity.
limited_deconstruct_can(Term::in, MaxArity::in,
        Functor::out, Arity::out, Arguments::out) :-
    rtti_implementation.deconstruct(Term, canonicalize,
        Functor, Arity, Arguments),
    Arity =< MaxArity.
limited_deconstruct_idcc(Term::in, _MaxArity::in,
        Functor::out, Arity::out, Arguments::out) :-
    % For this one, the caller checks Arity =< MaxArity.
    rtti_implementation.deconstruct(Term, include_details_cc,
        Functor, Arity, Arguments).

%-----------------------------------------------------------------------------%
