% The Java backend was using `value' as a field name inside enumeration
% classes, which conflicted with `value' function symbols in Mercury code.

:- module value_enum.
:- interface.

:- import_module io.

:- pred main(io::di, io::uo) is det.

%-----------------------------------------------------------------------------%
%-----------------------------------------------------------------------------%

:- implementation.

:- type ref_or_value
    --->    value
    ;       ref.

main(!IO) :-
    io.write(value, !IO),
    io.nl(!IO).

%-----------------------------------------------------------------------------%
% vim: ft=mercury ts=8 sts=4 sw=4 et
