# constants
: pi [  -> pi ]
    {} @erl.math.pi
;

# trigonometric functions
: sin [ rad -> x ]
    @erl.math.sin
;

: cos [ rad -> x ]
    @erl.math.cos
;

: tan [ rad -> x ]
    @erl.math.tan
;

: cot [ rad -> x ]
    dup cos swap sin /
;

: sec [ rad -> x ]
    cos 1 swap /
;

: csc [ rad -> x ]
    sin 1 swap /
;

# inverse trigonometry functions
: asin [ x -> rad ]
    @erl.math.asin
;

: acos [ x -> rad ]
    @erl.math.acos
;

: atan [ x -> rad ]
    @erl.math.atan
;

: acot [ x -> rad ]
    dup 0 < .{
        abs acot pi swap -
    } .{
        atan pi 2 / swap -
    } if
;

: asec [ x -> rad ]
    dup 0 < .{
        abs asec pi swap -
    } .{
        1 swap / acos
    } if
;

: acsc [ x -> rad ]
    dup 0 < .{
        abs acsc 0 swap -
    } .{
        pi 2 / swap asec -
    } if
;

# logarithms
: log [ x -> log ]
    @ex.kernel.log
;

: log2 [ x -> log2 ]
    @erl.math.log2
;

: log10 [ x -> log10 ]
    @erl.math.log10
;

# misc
: abs [ a -> b ]
    @ex.kernel.abs
;

: exp [ x -> exp ]
    @erl.math.exp
;

: sqrt [ x -> sqrt ]
    @erl.math.sqrt
;
