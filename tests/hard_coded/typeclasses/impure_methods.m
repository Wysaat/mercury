:- module impure_methods.
:- interface.

:- import_module io.

:- pred main(io__state::di, io__state::uo) is det.

:- typeclass c(T) where [
	impure pred m1(T::in) is det,
	semipure pred m2(T::in, int::out) is det
].

:- type foo ---> foo.

	% impure implementations of impure methods
:- instance c(foo) where [
	pred(m1/1) is foo_m1,
	pred(m2/2) is foo_m2
].

:- type goo ---> goo.

	% pure implementations of impure methods
:- instance c(goo) where [
	pred(m1/1) is goo_m1,
	pred(m2/2) is goo_m2
].

:- impure pred foo_m1(foo::in) is det.
:- semipure pred foo_m2(foo::in, int::out) is det.

:- pred goo_m1(goo::in) is det.
:- pred goo_m2(goo::in, int::out) is det.

:- implementation.

:- pragma promise_pure(main/2). 

main -->
	{ impure m1(foo) },
	{ impure m1(foo) },
	{ impure m1(foo) },
	{ impure m1(foo) },
	{ semipure m2(foo, X) },
	io__write_int(X),
	io__nl,

	{ impure m1(goo) },
	{ impure m1(goo) },
	{ impure m1(goo) },
	{ impure m1(goo) },
	{ semipure m2(goo, Y) },
	io__write_int(Y),
	io__nl.

:- pragma c_header_code("int foo_counter = 0;").

:- pragma c_code(foo_m1(_F::in), "foo_counter++;").
:- pragma c_code(foo_m2(_F::in, Val::out), "Val = foo_counter;").

:- pragma foreign_code("C#", "static int foo_counter = 0;").

:- pragma foreign_proc("C#", foo_m1(_F::in),
		[], "foo_counter++;").
:- pragma foreign_proc("C#", foo_m2(_F::in, Val::out),
		[promise_semipure], "Val = foo_counter;").

goo_m1(_).
goo_m2(_, 42).


