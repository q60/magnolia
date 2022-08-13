: str>letters [ str -> list ]
    @ex.string.graphemes
;

: str>chars [ str -> list ]
    @ex.string.to_charlist
;

: letters>str [ list -> str ]
    @ex.enum.join
;

: chars>str [ list -> str ]
    @ex.list.to_string
;

: join [ list sep -> str ]
    swap {}
    swap + swap +
    @ex.enum.join
;

: split [ str pattern -> list ]
    swap {}
    swap + swap +
    @ex.string.split
;
