:- module fib_float.

:- interface.

:- import_module io.

:- pred main(io__state::di, io__state::uo) is cc_multi.

:- implementation.

:- import_module benchmarking, require, int, float.

main -->
	perform_trials(20.0).

:- pred perform_trials(float::in, io__state::di, io__state::uo) is cc_multi.

perform_trials(N) -->
	{ trial(N, Time, MTime) },
	% io__write_float(N),
	% io__write_string(": "),
	% io__write_int(Time),
	% io__write_string("ms vs "),
	% io__write_int(MTime),
	% io__write_string("ms\n"),
	(
		{
			Time > 10 * MTime,
			MTime > 0	% untabled takes ten times as long
		;
			Time > 100,	% untabled takes at least 100 ms
			MTime < 1	% while untabled takes at most 1 ms
		}
	->
		io__write_string("tabling works\n")
	;
		{ Time > 10000 }	% Untabled takes at least 10 seconds
	->
		io__write_string("tabling does not appear to work\n")
	;
		% We couldn't get a measurable result with N,
		% and it looks like we can afford a bigger trial
		perform_trials(N + 3.0)
	).

:- pred trial(float::in, int::out, int::out) is cc_multi.

trial(N, Time, MTime) :-
	benchmark_det(fib, N, Res, 1, Time),
	benchmark_det(mfib, N, MRes, 1, MTime),
	require(unify(Res, MRes), "tabling produces wrong answer").

:- pred fib(float::in, float::out) is det.

fib(N, F) :-
	( N < 2.0 ->
		F = 1.0
	;
		fib(N - 1.0, F1),
		fib(N - 2.0, F2),
		F is F1 + F2
	).

:- pred mfib(float::in, float::out) is det.
:- pragma memo(mfib/2).

mfib(N, F) :-
	( N < 2.0 ->
		F = 1.0
	;
		mfib(N - 1.0, F1),
		mfib(N - 2.0, F2),
		F is F1 + F2
	).
