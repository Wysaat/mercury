:- module aditi_update_errors.

:- interface.

:- import_module aditi.

:- pred aditi_update_syntax(aditi__state::aditi_di,
	aditi__state::aditi_uo) is det.

:- pred aditi_update_derived_relation(aditi__state::aditi_di,
	aditi__state::aditi_uo) is det.

:- pred aditi_update_types(aditi__state::aditi_di,
	aditi__state::aditi_uo) is det.

:- implementation.

:- import_module int.

:- pred p(aditi__state::aditi_ui, int::out, int::out) is nondet.
:- pragma base_relation(p/3).

:- func q(aditi__state::aditi_ui, int::out) = (int::out) is nondet.
:- pragma base_relation(q/2).

:- pred anc(aditi__state::aditi_ui, int::out, int::out) is nondet.
:- pragma aditi(anc/3).

aditi_update_syntax -->
	X = p(_, 1, 2),
	aditi_insert(X),

	aditi_insert(p(_, 1, 2), foo),
	aditi_insert(q(_, 1) = 2, foo),

	aditi_delete(p(_, X, _Y) :- X < 2, foo),
	aditi_delete(q(_, X) = _Y :- X < 2, foo),

	{ DeleteP =
		(aditi_top_down pred(_::unused, 1::in, 2::in) is semidet :-
			true
		) },
	aditi_delete(p/3, DeleteP),

	{ DeleteQ =
		(aditi_top_down func(_::unused, 1::in) = (2::in) is semidet)
	},
	aditi_delete(q/2, DeleteQ),

	{ InsertP =
	    (aditi_bottom_up pred(_::aditi_ui, A1::out, A2::out) is nondet :-
		( A1 = 1, A2 = 2
		; A1 = 2, A2 = 3
		)
	    ) },
	aditi_bulk_insert(p/3, InsertP),
	aditi_bulk_delete(pred p/3, InsertP, foo),

	{ InsertQ =
	    (aditi_bottom_up func(_::aditi_ui, A1::out)
	    		= (A2::out) is nondet :-
		( A1 = 1, A2 = 2
		; A1 = 2, A2 = 3
		)
	    ) },
	aditi_bulk_delete(q/2, InsertQ),
	aditi_bulk_delete(func q/2, InsertQ, foo),

	aditi_modify(p(_, X0, Y0) ==> p(_, X0 + 1, Y0 + 1)),
	aditi_modify((q(_, X0) = Y0) ==> (q(_, X0 + 1) = (Y0 + 1))),
	aditi_modify(q(_, _X0) ==> _Y0),

	{ ModifyP =
	    (aditi_top_down pred(_::unused, X0::in, Y0::in,
			_::unused, X::out, Y::out) is semidet :-
		X0 = 1,
		X = X0 + Y0,
		Y = X0 - Y0
	    ) },
	aditi_modify(p/3, ModifyP),
	aditi_modify(pred p/3, ModifyP, foo),

	{ ModifyQ =
	    (aditi_top_down pred(_::unused, X0::in, Y0::in,
			_::unused, X::out, Y::out) is semidet :-
		X0 = 1,
		X = X0 + Y0,
		Y = X0 - Y0
	    ) },
	aditi_modify(q/2, ModifyQ),
	aditi_modify(func q/2, ModifyQ, foo).

aditi_update_derived_relation -->
	aditi_insert(anc(_, 1, 2)).	

aditi_update_types -->
	aditi_insert(p(_, 1)),
	aditi_insert(q(_, 1)),
	aditi_insert(q(_) = 2),
	{ aditi_insert(p(_, 1, 2), 1, _) },

	aditi_delete(p(_, X, _Y) :- X < 2.0),
	aditi_delete(q(_, X) = _Y :- X < 2.0),

	aditi_delete(p(_, X) :- X < 2.0),
	aditi_delete(q(_) = Y :- Y < 2),

	{ DeleteP =
		(aditi_top_down pred(_::unused, 2::in) is semidet :-
			true
		) },
	aditi_delete(pred p/3, DeleteP),
	aditi_delete(pred q/2, DeleteP),

	{ DeleteQ =
		(aditi_top_down func(_::unused) = (2::in) is semidet)
	},
	aditi_delete(func q/2, DeleteQ),
	aditi_delete(func p/3, DeleteQ),

	{ DeleteQ2 =
		(func(_::unused) = (2::in) is semidet)
	},
	aditi_delete(func q/2, DeleteQ2),

	{ InsertP =
	    (aditi_bottom_up pred(_::aditi_ui, A1::out, A2::out) is nondet :-
		( A1 = 1, A2 = 2.0
		; A1 = 2, A2 = 3.0
		)
	    ) },
	aditi_bulk_insert(pred p/4, InsertP),
	aditi_bulk_insert(pred p/3, InsertP),
	aditi_bulk_delete(pred q/2, InsertP),

	{ InsertP2 =
	    (pred(_::aditi_ui, A1::out, A2::out) is nondet :-
		( A1 = 1, A2 = 2.0
		; A1 = 2, A2 = 3.0
		)
	    ) },
	aditi_bulk_insert(pred p/3, InsertP2),

	{ InsertQ =
	    (aditi_bottom_up func(_::aditi_ui, A1::out)
	    		= (A2::out) is nondet :-
		( A1 = 1, A2 = 2
		; A1 = 2, A2 = 3
		)
	    ) },
	aditi_bulk_insert(func q/2, InsertQ),
	aditi_bulk_insert(pred q/2, InsertQ),
	aditi_bulk_delete(func q/2, InsertQ),

	aditi_modify(p(X0, Y0, _) ==> p(X0 + 1, Y0 + 1, _)),
	aditi_modify((q(_) = Y0) ==> (q(_) = (Y0 + 1))),
	aditi_modify(q(_, X0, Y0) ==> q(_, X0 + 1, Y0 + 1)),

	{ ModifyP =
	    (aditi_top_down pred(_::unused, X0::in, Y0::in,
			_::unused, X::out, Y::out) is semidet :-
		X0 = 1.0,
		X = X0 + Y0,
		Y = X0 - Y0
	    ) },
	aditi_modify(pred p/3, ModifyP),

	{ ModifyQ =
	    (aditi_top_down func(_::unused, X0::in, Y0::in,
			_::unused, X::out) = (Y::out) is semidet :-
		X0 = 1,
		X = X0 + Y0,
		Y = X0 - Y0
	    ) },
	aditi_modify(func q/2, ModifyQ).

