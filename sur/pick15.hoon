::
::::  /sur/toe/hoon
::
|%
+=  grid         (list [%klr styx])
+=  outcome      ?(%wins %tie ~)
+=  player       [=stone color=tint =ship]
+=  coord        ?(%1 %2 %3)
+=  stone        ?(%1 %2 %3 %4 %5 %6 %7 %8 %9)
+=  spot         [coord coord]
+=  board        (map spot player)
+=  game         ?(%opponent %confirm %start %replay)
+=  remote-app   ::  $in: for incoming subscriptions
                 ::    used when a ship sends a %peer
                 ::  $out: for outgoing subscriptions
                 ::    used when we %peer a ship
                 ::
                 [ze=ship subs=[in=bone out=bone]]
+=  subscribers  ::  Gall has prey:pubsub:userlib to get the list
                 ::  of subscribers.
                 ::  It uses a
                 ::    $bitt: (map bone (pair ship path))
                 ::  to track  incoming subs
                 ::  TODO: don't reinvent the wheel and just use
                 ::        the queue to track the order or subs.
                 ::
                 (qeu remote-app)
:: +=  message      ?(%accept %rematch)
::
::  Marks sent in each move, as defined in %/mar/toe/
::
+=  pick15-play     ?(%accept %rematch)
+=  pick15-winner   [out=tape tur=pick15-turno]
+=  pick15-turno    [=stone =spot]
+=  pick15-cancel   %bye
--
