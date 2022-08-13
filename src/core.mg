: drop2 [ x y ->  ]
    drop drop
;

: drop3 [ x y z ->  ]
    drop2 drop
;

: dup2 [ x y -> x y x y ]
    over over
;
