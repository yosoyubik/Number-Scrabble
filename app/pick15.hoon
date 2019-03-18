::
::
::::  /hoon/toe/app
::
::
::  zuse version
::
/?  310
::  toe structures
::
/-  pick15
::  libraries
::
/+  cola, sole
::  exposes namespace
::
[. pick15 sole]
=,  cola
::  stack trace on
::
!:
::
=>  |%
    +|  %models
    ::
    +$  state      $:  ::
                       ::  $game-state: current game state (see %/sur/toe/hoon)
                       ::
                       game-state=game
                       ::
                       ::  $game-board: game internal board
                       ::
                       game-board=board
                       ::
                       ::  $consol: console state
                       ::
                       ::     $conn: number id for console connection
                       ::     $state: console's state (from sole-share)
                       ::
                       consol=[conn=bone state=sole-share:sole]
                       ::
                       ::  $toers: each player has an icon (%x or %o)
                       ::
                       toers=(map ship player)
                       ::
                       ::  $me: alias for player's identity
                       ::    (instead of src.bol)
                       ::    FIXME: use =* instead?
                       ::
                       me=ship
                       ::
                       ::  $who: player that owns the turn
                       ::                       ::
                       who=ship
                       ::
                       ::  %next: flag to indicate a replay
                       ::
                       next=?
                       ::
                       ::  $opos: queue of players waiting to play
                       ::
                       ::    TODO: explore $bitt: (map bone (pair ship path))
                       ::          (more info in %/sur/toe/hoon)
                       ::
                       opos=subscribers
                   ==
    +$  move       (pair bone card)
    +$  card       $%  [%diff diff-data]
                       [%peer wire dock path]
                       [%pull wire dock ~]
                       [%poke wire dock poke-data]
                       [%wait wire p=@da]
                   ==
    +$  diff-data  $%  ::  See %/mar/toe/* for specific details
                       ::    * = [turno, player, winner]
                       ::
                       [%pick15-turno pick15-turno]
                       [%pick15-play pick15-play]
                       [%pick15-winner pick15-winner]
                       ::  $sole-effect: console specific move
                       ::
                       [%sole-effect sole-effect:sole]
                   ==
    +$  poke-data  [%pick15-cancel pick15-cancel]
    ::  FIXME: $spot has to be redefined
    ::     even though it's already in sur...
    ::
    +$  spot  [coord coord]
    ::
    +|  %constants
    ::
    ++  welcome         :-  %klr
                        :~  [[~ ~ ~] "     "]
                            [[`%un ~ ~] "3-to-15"]
                        ==
    ++  brought-by      "brought to you by W.O.P.R {copyright}  "
    ++  wopr            txt+(weld empties brought-by)
    ++  falken-tan      :-  %tan
                        %-  flop
                        :~  leaf+" Greetings professor Falken."
                            leaf+" A strange game."
                            leaf+" They only winning move is not to play."
                        ==
    ++  falken          :~  klr+~[[[`%un ~ ~] "Greetings professor Falken."]]
                            klr+~[[[`%un ~ ~] "A strange game."]]
                            klr+~[[[`%un ~ ~] "They only winning move is not to play."]]
                        ==
    ++  choose          " | shall we play a game? (e.g. ~zod) | "
    ++  waiting         " | waiting for "
    ++  abort           "(!=quit)"
    ++  keep-on         " continue? (Y/N) | "
    ++  confirm         " | play with "
    ++  instruct        klr+~[no-klr [[```%b] "* choose a board position (e.g. 2/2)"]]
    ++  row-sep         klr+~[[[~ ~ ~] "    ---------"]]
    ++  no-subscribers  klr+~[no-klr [[```%b] "* no players yet..."]]
    ++  frowned-upon    :-  %klr
                        :~  [[~ ~ ~] " "]
                            :-  [```%y]
                            "* playing with yourself is frowned upon... "
                        ==
    ++  new-line        txt+""
    ++  empties         "                 "
    ++  no-klr          [[~ ~ ~] " "]
    ++  empty-style     klr+~[no-klr]
    ++  copyright       (trip (tuft `@c`169))
    ++  spot-taken      klr+~[no-klr [[```%r] "* spot taken"]]
    ++  wait-your-turn  klr+~[no-klr [[```%r] "* wait for your turn"]]
    ++  stone-is-used   klr+~[no-klr [[```%r] "* that stone is already used"]]
    ::  $clear: clears the screen
    ::
    ++  clear     clr+~
    ::  $reset: resets the prompt
    ::
    ++  reset     set+~
    --
::
::  %app
::
::    Our app is defined as a "door" (multi-armed core with a sample).
::    Arms are grouped in chapters (+|) based on common functionality
::
|_  [bol=bowl:gall state]
::
::  %state
::
::    Arms to innitialized (and restart) our app's state
::
+|  %state
::
++  this
  ::  Common idiom to refer to our whole %app and its context
  ::
  .
::
++  prep
  ::  TODO: we need to treat old state differently,
  ::    rather than reseting everything all the time
  ::
  |=  old=(unit state)
  ^-  (quip move _this)
  ?~  old
    ::  we haven't modified the previous state
    ::
    (wipe ~)
  ::  the old state needs to be adapted to the new one
  ::
  (restore [~ ^-(state u.old)])
::
++  wipe
  |=  moves=(list move)
  ^-  (quip move _this)
  :-  moves
  %=  this
      me          our.bol
      next        %.n
      opos        ~
      toers       ~
      game-board  ~
      game-state  %opponent
  ==
::
::  TODO: something needs to be fixed here...
::
++  restore
  |=  [moves=(list move) state]
  ^-  (quip move _this)
  :-  moves
  %=  this
      me          our.bol
      next        %.n
      opos        ~
      toers       ~
      game-board  ~
      game-state  %opponent
  ==
::
::  After timer kicks, we reset the prompt, cleaning the log message
::    FIXME: breaks %sole, more research needed...
::
++  wake
  |=  [wir=wire ~]
  ^-  (quip move _this)
  =^  edit  state.consol  (transmit-sole reset)
  [[(effect det+edit)]~ this]
::
::  %core
::
::    Game engine core logic
::
+|  %core
::
++  ge
  ::
  |_  buf=sole-buffer:sole
  ::
  ::  $select-opponent: step 1
  ::    sends a request to play to opponent (e.g. ~zod)
  ::
  ::    FIXME:  error when app is not running
  ::            gall: %toe: move: invalid card (bone 0)
  ::            mack
  ::
  ++  select-opponent
    ^-  (quip move _this)
    =/  try  (rust (tufa buf) ;~(pfix sig fed:ag))
    ?~  try
      [~ this]
    ?:  =(u.try me)
      :_  this
      ~[(effect frowned-upon)]
    =^  edit  state.consol  (transmit-sole reset)
    =/  new-prompt  (prompt "{waiting}{(scow %p u.try)} {abort} | ")
    :_  ::  $in=0: we haven't received a subscribe back yet so
        ::  by convention we assign 0 to the incoming subscription
        ::
        this(opos (~(put to opos) [u.try [in=0 out=ost.bol]]))
    :~  (effect mor+~[det+edit new-prompt])
        [ost.bol %peer /join-game [u.try dap.bol] /invite]
    ==
  ::
  ::  $wait-confirm: step 2
  ::    after reaciving a request to play, we block until
  ::    the console receives a comfirmation [Y/N] answer
  ::
  ++  wait-confirm
    ^-  (quip move _this)
    =/  try  (rust (cass (tufa buf)) (mask "yn"))
    ?~  try
      [~ this]
    ?:  =(u.try 'n')
      ::  don't play with this player
      ::
      crash-current-game
    ::  play with $opo: 1st incoming sub in the queue
    ::
    ?~  opos
      ::  current player might have crashed zir game
      ::
      crash-current-game
    =/  guest    (need ~(top cola opos))
    =/  new-opos  [~(nap cola opos) [ze.guest [in.subs.guest ost.bol]]]
    ::  cleans up the prompt
    ::
    =^  edit  state.consol  (transmit-sole reset)
    ::  by default, the first turn is mine
    ::    (the one who received the request)
    ::
    :_  %=  this
          who  me
          game-state  %start
          opos  (update-queue-head new-opos)
        ==
    :~  ::  after we confirm, we subscribe to our opponent
        ::    TODO: research 2-way subscription model with Hall
        ::
        [ost.bol %peer /join-game [ze.guest dap.bol] /back]
        ::  We send $accept to our subscriber
        ::
        (send-message %accept)
        %-  effect
        :~  %mor
            det+edit
            (prompt (create-dial ze.guest))
    ==  ==
  ::
  ::  $moves-start: step 3
  ::    now the game is on, each player will send diffs
  ::    to each other with the position for zir icon
  ::
  ++  moves-start
    ^-  (quip move _this)
    =/  new-turn  (rust (tufa buf) user-input)
    ?~  new-turn
      [~ this]
    ?.   =(our.bol who)
      :_  this
      ~[(effect wait-your-turn)]
    :: ?:  (~(has by game-board) (spot-val (need new-move)))
    =/  parsed-turn  (turno-validation (need new-turn))
    =/  player-stone  [stone.parsed-turn %g src.bol]
    =/  new-move  [spot.parsed-turn player-stone]
    ?.  =(~ (~(get by game-board) spot.parsed-turn))
      :_  this
      ~[(effect spot-taken)]
    ?.  (valid-move parsed-turn)
      :_  this
      ~[(effect stone-is-used)]
    =^  edit  state.consol  (transmit-sole reset)
    =^  out  game-board  (step new-move)
    ?~  out
      =/  guest  (need ~(top cola opos))
      ::  we switch turns
      ::
      :_  this(who ze.guest)
      :~  (send-turno parsed-turn)
          %-  effect
          :~  %mor
              mor+print-grid
              det+edit
              (prompt (create-dial ze.guest))
      ==  ==
    ::  game ends
    ::
    :_  this(game-board ~, game-state %replay)
    :~  (send-winner [(end-message out) parsed-turn])
        %-  effect
        :~  %mor
            mor+print-grid
            det+edit
            (prompt "{(end-message out)}{keep-on}")
    ==  ==
  ::
  ::  $continue-replay: step 4
  ::    the game has finished, either with a win or a tie
  ::    now we block to confirm if the players want to continue
  ::
  ++  continue-replay
    ^-  (quip move _this)
    =/  try  (rust (cass (tufa buf)) (mask "yn"))
    ?~  try
      [~ this]
    ?:  =(u.try 'n')
      crash-current-game
    =^  edit  state.consol  (transmit-sole reset)
    =.  game-board  ~
    :: =/  icons   (get-icons (~(got by toers) me))
    =/  guest    (need ~(top cola opos))
    =/  rematch  (send-message %rematch)
    ::  checks if ze (opponent) has already confirmed?
    ::
    ?:  =(next %.y)
      :_  this(game-state %start, who ze.guest, next %.n)
      :~  rematch
          %-  effect
          :~  %mor
              mor+print-grid
              det+edit
              (prompt (create-dial ze.guest))
      ==  ==
    :_  this(game-state %replay, next %.y)
    :~  rematch
        %-  effect
        :~  %mor
            det+edit
            (prompt " | ...waiting for {(cite:title ze.guest)} {abort} |")
    ==  ==
  ::
  --
::
::  %comunication
::
::    Gall-related arms for urbit-to-urbit communication
::
+|  %comms
::
::  $peer-invite: receives/enqueues a request to start a game
::
::    if a game is ongoing (or more than one request in queue),
::    enqueues the new request or asks for confirmation if no active games.
::
++  peer-invite
  |=  pax=path
  ^-  (quip move _this)
  =/  guest  (cite:title src.bol)
  ::  $out=0: we haven't subscribed back yet so
  ::  by convention we assign 0 to the out subs
  ::
  =/  invite  [src.bol [ost.bol 0]]
  ?~  opos
    :-  ~[(effect (prompt "{confirm}{guest}? (Y/N) | "))]
    %=  this
      game-state   %confirm
      ::  first invite goes into the subscribers queue
      ::
      opos   (~(gas to `subscribers`~) [invite ~])
    ==
  ::  FIXME: why the cast? (`subscribers`opos)
  ::
  :_  this(opos (~(put to `subscribers`opos) invite))
  ~[(effect klr+[[[```%b] " [ {guest} wants to play ]"] ~])]
  ::  FIXME: this is supposed to show log mesasges in the prompt that
  ::    are later wiped out by the +wake arm but we got a:
  ::    [%receive-sync [%his 5 4] %own 4 4]
  ::
  :: =/  request  ^-(sole-edit set+(tuba " [{guest} wants to play] "))
  :: =^  edit  state.consol  (transmit-sole request)
  :: :_  this(opos (~(put to `subscribers`opos) invite))            :: save request to play
  :: :~  (effect det+edit)
  ::     [ost.bol %wait / `@da`(add now.bol ~s3)]
  :: ==
::
::  $peer-back: subscribes back to the ship that requested to play with us
::
::    (received on opponent's ship from a 'subscribe-back' move)
::
++  peer-back
  |=  pax=path
  ^-  (quip move _this)
  =/  opo  (need ~(top cola opos))
  =/  new-head  ^-(remote-app [ze.opo [in=ost.bol out=out.subs.opo]])
  :-  ~
  this(opos (update-queue-head [~(nap cola opos) new-head]))
::
++  reap
  |=  [wir=wire err=(unit tang)]
  ^-  (quip move _this)
  ?~  err  [~ +>]
  :_  +>.$
  ~[(effect tan+u.err)]
::
::  $diff-pick15-player: innvite accepted with we our opponent's icon
::
::    hardcoded %x as our opponent's icon.
::
++  diff-pick15-play
  |=  [wir=wire msg=pick15-play]
  ^-  (quip move _+>)
  ::  %per: player of our opponent
  ::    +get-icons expected the player to be our, so we switch
  ::
  :: =/  icons  (get-icons (switch `per))
  ?-    msg
      ::  %accept: first match
      ::
      %accept
    ::  toers needs to be modifed before we send the new state
    ::    since create dial can't access a future state
    ::
    :: =.  toers  %-  ~(gas by toers)
    ::            :~  [our.bol [(switch-player `per) %g]]
    ::                [src.bol [stone.per %r]]
    ::            ==
    :_  +>.$(game-state %start, who src.bol)
    :_  ~
    %-  effect
    :~  %mor
        (prompt (create-dial src.bol))
    ==
  ::
      ::  %rematch: game has endend
      ::
      %rematch
    ::  check if already said yes?
    ::
    ?.  next
      [~ +>.$(next %.y)]
    =.  game-board  ~
    =/  guest  (need ~(top cola opos))
    :_  +>.$(game-state %start, who me, next %.n)
    :_  ~
    %-  effect
        :~  %mor
            mor+print-grid
            (prompt (create-dial ze.guest))
  ==    ==
::
++  send-message
  |=  msg=pick15-play
  ^-  move
  =/  guest  (need ~(top cola opos))
  [in.subs.guest %diff %pick15-play msg]
::
++  diff-pick15-winner
  |=  [wir=wire win=pick15-winner]
  ^-  (quip move _+>)
  =/  player-stone  [stone.tur.win %r src.bol]
  ::  puts the winner move on the board
  ::
  =^  out  game-board  (step [spot.tur.win player-stone])
  :_  +>.$(game-state %replay)
  :_  ~
  %-  effect
  :~  %mor
      mor+print-grid
      new-line
      (prompt "{out.win}{keep-on}")
  ==
::
::  %send-winner: spams our opponent with the winner move
::
++  send-winner
  |=  win=pick15-winner
  ^-  move
  =/  guest  (need ~(top cola opos))
  [in.subs.guest %diff %pick15-winner win]
::
++  diff-pick15-turno
  |=  [wir=wire turno=pick15-turno]
  ^-  (quip move _+>.$)
  ::  puts the opponent's move on the  board
  ::
  =^  out  game-board  (step [spot.turno [stone.turno %r src.bol]])
  ::  %get-icons expected the player to be ours
  ::    but per.tur is our opponent, so we switch
  ::
  =/  guest  (need ~(top cola opos))
  ::  now is our turn
  ::
  :_  +>.$(who me)
  :_  ~
  %-  effect
  :~  %mor
      mor+print-grid
      (prompt (create-dial ze.guest))
  ==
::
::  $send-turno: spams our opponent with our game move (turno)
::
++  send-turno
  |=  turno=pick15-turno
  ^-  move
  =/  guest  (need ~(top cola opos))
  [in.subs.guest %diff %pick15-turno turno]
::
++  send-unsubscribe
  |=  guest=remote-app
  ^-  (quip move _this)
  =/  peer-move  [out.subs.guest %pull /join-game [ze.guest dap.bol] ~]
  =^  edit  state.consol  (transmit-sole reset)
  =.  game-board  ~
  =/  effects  ~[det+edit clear welcome new-line mor+print-grid (prompt choose)]
  ?~  ~(nap cola opos)
    (wipe ~[(effect mor+effects) peer-move])
  =/  new-guest  (cite:title ze:(need ~(top cola ~(nap cola opos))))
  :_  %=  this
        opos  ~(nap cola opos)
        game-state  %confirm
      ==
  :~  peer-move
      %-  effect
      :~  %mor
          det+edit
          (prompt "{confirm}{new-guest} (Y/N)? | ")
      ==
  ==
::
::  $pull-back: handles logic for ending subscriptions
::
::    we only handle /back cases, to stop communiaction
::    with a ship that requested to play with us
::
++  pull
  ::  TODO:
  ::    is it possible to get a %pull from a ship who didn't %peer?
  ::
  |=  pax=path
  ^-  (quip move _this)
  ::  if we receive a random pull, do nothing
  ::    FIXME: is this even necessary?
  ::
  ?~  opos  [~ this]
  :: =/  leaving-guest  (need ~(top cola opos))
  =/  shortened-ship  (cite:title src.bol)
  =/  out  klr+~[[[```%b] " [{shortened-ship} cancelled your game...]"]]
  ?~  ~(nap cola opos)
    =.  game-board  ~
    ::  FIXME: we send the edit in two cases (duplicated code)
    ::
    =^  edit  state.consol  (transmit-sole reset)
    ::  FIXME: this needs to be shortened
    ::
    =/  effects  ~[det+edit clear out welcome new-line mor+print-grid (prompt choose)]
    ::  if we had only one opponent in the queue, reset
    ::
    (wipe ~[(effect mor+effects)])
  ::  we need to find who in the queue unsubscribed
  ::    we only need src.bol, we bunt the in/out bones
  ::
  =/  new-q  (remove-from-queue [opos [src.bol [*bone *bone]]])
  =/  new-guest  (cite:title ze:(need ~(top cola new-q)))
  ::  we get a cancel from the first in the queue
  ::
  ?.  =(src.bol ze:(need ~(top cola opos)))
    ::  we get a cancel from someone waiting in the queue
    ::  the current game needs to keep going, the queue is updated
    ::  silently, and we inform the app of the event
    ::
    :_  this(opos new-q)
    ~[(effect out)]
  ::  we get a cancel from the first in the queue
  ::
  =^  edit  state.consol  (transmit-sole reset)
  :_  %=  this
        opos  new-q
        game-state  %confirm
        game-board   ~
      ==
  ::  we ask for confirmation to the next in the queue
  ::
  :~  %-  effect
      :~  %mor
          det+edit
          out
          (prompt "{confirm}{new-guest} (Y/N)? |  ")
      ==
  ==
::
::  $send-cancel: sends a manual cancel to a ship that peered us
::
++  send-cancel
  |=  guest=remote-app
  ^-  (quip move _this)
  =/  poke-move  [ost.bol %poke /cancel [ze.guest dap.bol] [%pick15-cancel %bye]]
  =^  edit  state.consol  (transmit-sole reset)
  =/  tabla  mor+print-grid
  =/  effects  ~[det+edit clear welcome new-line tabla (prompt choose)]
  ?~  ~(nap cola opos)
    (wipe ~[(effect mor+effects) poke-move])
  =/  rest-q  ~(nap cola opos)
  =/  new-guest  (cite:title ze:(need ~(top cola rest-q)))
  :_  %=  this
        game-board  ~
        game-state  %confirm
        opos  rest-q
      ==
  :~  poke-move
      %-  effect
      :~  %mor
          det+edit
          (prompt "{confirm}{new-guest} (Y/N)? | ")
      ==
  ==
::
::  $poke-pick15-cancel: manual pull subscription
::
::    poking the app with a pick15-cancel mark
::    for a pull on the guest ship
::
++  poke-pick15-cancel
  |=  bye=pick15-cancel
  ^-  (quip move _this)
  ::  if we receive a random cancel, do nothing
  ::
  ?~  opos  [~ this]
  ::  the manual pull can only be sent by our current guest
  ::
  ?.  =(src.bol ze:(need ~(top cola opos)))
    ::  if someone we didn't peer pokes us, do nothing
    [~ this]
  ::
  =/  current-guest  (need ~(top cola opos))
  =/  shortened-ship  (cite:title ze.current-guest)
  =/  out  klr+~[[[```%b] " [{shortened-ship} cancelled your game...] "]]
  =^  edit  state.consol  (transmit-sole reset)
  ?~  ~(nap cola opos)
    ::  if we had only one opponent in the queue, reset
    ::    $effects: FIXME (this needs to be shortened)
    ::
    =/  effects  ~[det+edit clear out welcome new-line mor+print-grid (prompt choose)]
    (wipe ~[(effect mor+effects)])
  =/  rest-q  ~(nap cola opos)
  =/  new-guest  (cite:title ze:(need ~(top cola rest-q)))
  :_  %=  this
        game-state  %confirm
        opos  rest-q
      ==
  :~  %-  effect
      :~  %mor
          det+edit
          out
          (prompt "{confirm}{new-guest} (Y/N)? | ")
      ==
  ==
::
::  $poke-atom: manual reset
::
::    poking the app with any atom will do a manual wipe of the state
::
++  poke-atom
  |=  a=@
  ^-  (quip move _+>)
  %-  wipe
  ~[(effect mor+~[clear welcome new-line mor+print-grid (prompt choose)])]
::
++  coup
  |=  [wir=wire err=(unit tang)]
  ?~  err  [~ +>]
  :_  +>.$
  ~[(effect tan+u.err)]
::
::  %console
::
::    %sole arms to receive console moves and prompt formatting
::
+|  %console
::
++  poke-sole-action
  |=  act=sole-action:sole
  ^-  (quip move _+>)
  ::  FIXME: should an alias be used instead?
  ::
  =*  share  state.consol
  ?-    -.act
    ::  $clr: clear screen
    ::
    $clr  [~ this]
    ::  $ret: enter key pressed
    ::
    $ret  ?~  buf.share  [~ this]
          ::  checks for a restart game command
          ::
          =/  restart  (rust (tufa buf.share) ;~(just zap))
          ?.  =(~ restart)  crash-current-game
          ::  checks for a "list waiting opponents" command
          ::
          =/  list  (rust (tufa buf.share) ;~(just (just 'l')))
          ?.  =(~ list)  list-subscribers
          ::  %egg
          ::
          ::    ?
          ::
          =/  egg  (rust (tufa buf.share) ;~(just (jest (crip "joshua"))))
          ?.  =(~ egg)  easter-egg
          ::  based on the current state, a different engine arm is called
          ::
          ?-    game-state
              ::  Game Engine Step 1: selects opponent
              ::
              %opponent  ~(select-opponent ge buf.share)
              ::  Game Engine Step 2: waits for confirmation
              ::
              %confirm   ~(wait-confirm ge buf.share)
              ::  Game Engine Step 3: moves start
              ::
              %start     ~(moves-start ge buf.share)
              ::  Game Engine Step 4: game ends, waits for end/continue?
              ::
              %replay    ~(continue-replay ge buf.share)
          ==
    ::  $det: key press
    ::    FIXME: when code updats, it errors here:
    ::           [%receive-sync [%his 4 0] %own 2 0]
    ::           lib/sole/hoon:<[103 5].[103 7]>
    ::           [%drum-coup-fail ~zod 1 p=~zod q=%toe]
    ::
    $det  =^  inv  state.consol  (~(transceive sole share) +.act)
          [~ this]
  ==
::
::  $peer-sole: sole's subscription arm that connects to the console
::
++  peer-sole
  |=  path
  ^-  (quip move _this)
  =.  consol  [ost.bol *sole-share:sole]
  :_  this
  :~  %-  effect
      mor+~[clear welcome wopr mor+print-grid (prompt choose)]
  ==
::
++  effect
  |=  fec=sole-effect:sole
  ^-  move
  [conn.consol %diff %sole-effect fec]
::
++  transmit-sole
  |=  inv=sole-edit
  ^-  [sole-change sole-share]
  (~(transmit sole state.consol) inv)
::
::  $prompt: default game input that modifies the prompt
::
++  prompt
  |=  dial=styx
  ^-  sole-effect:sole
  pro+[& %$ dial]
::
++  create-dial
  ::  +cite:title compresses the ship's name if
  ::    we are dealing with a comet
  ::
  |=  guest=ship
  ^-  styx
  :~  [[~ ~ ~] " | "]
      [[```%g] "{(cite:title me)}"]
      [[~ ~ ~] " vs "]
      [[```%r] "{(cite:title guest)}"]
      [[~ ~ ~] " | ["]
      [[```%b] "number-row/col"]
      [[~ ~ ~] "] "]
  ==
::
::  $print-row: pretty prints a row of the board displayed on the console
::
++  print-row
  |=  row=@
  ^-  [%klr styx]
  =/  col  1
  :-  %klr
  |-  ^-  styx
  =/  symbol  (~(get by game-board) [row col])
  =/  stone   (get-icon symbol)
  =/  color   (get-color symbol)
  ?:  &(=(%4 col))
    ~
  :-  ?:  &(=(col %1))
        [[~ ~ ~] "    "]
      [[~ ~ ~] "| "]
  [[[~ ~ `color] "{stone} "] $(col (add col 1))]
::
::  $print-grid: pretty prints the board displayed on the console
::
++  print-grid
  ^-  grid
  :~  (print-row 1)  row-sep
      (print-row 2)  row-sep
      (print-row 3)
      empty-style
  ==
::
++  end-message
  |=  out=outcome
  ^-  tape
  ?:(=(out %tie) " It's a tie!" " | {<who>} wins!")
::
++  list-subscribers
  ^-  (quip move _this)
  =^  edit  state.consol  (transmit-sole reset)
  ?~  opos
    [~[(effect mor+~[det+edit no-subscribers])] this]
  :_  this
  :~  %-  effect
          :~  %mor
              (queue-to-list opos)
              det+edit
  ==      ==
::
++  crash-current-game
  ^-  (quip move _this)
  ?~  opos
    [~ this]
  =/  current-guest  (need ~(top cola opos))
  ?:  ::  if we haven't confirmed current subscription
      ::
      =(0 out.subs.current-guest)
    ::  send cancel poke
    ::
    (send-cancel current-guest)
  ::  if subscribed, %pull subscription
  ::
  (send-unsubscribe current-guest)
::
::  %rules
::
::    Pattern matching on console's input
::
+|  %rules
::
++  stone-rule  (cook |=(a/@ (sub a '0')) (shim '1' '9'))
++  index-rule  (cook |=(a/@ (sub a '0')) (shim '1' '3'))
++  position
  ::  e.g. [1-3]/[1-3]
  ::
  ;~((glue fas) index-rule index-rule)
::
++  user-input
  ::  [1-9]-[1-3]/[1-3]
  ::    e.g:  1-3/3
  ::
  ;~(plug ;~(sfix stone-rule hep) position)
::
++  turno-validation
  |=  a=[@ [@ @]]
  ?>(?=(pick15-turno a) a)
::
::  %game
::
::     Arms for game-specific actions
::
+|  %game
::
++  valid-move
  |=  turno=pick15-turno
  ^-  ?
  ?&  (valid-line turno)
      (valid-column turno)
      (valid-square turno)
  ==
::
++  valid-line
  |=  turno=pick15-turno
  ^-  ?
  =+  i=0
  |-
  ?:  =(i 4)
    %.y
  =/  c=(unit player)  (~(get by game-board) [-.spot.turno i])
  ?.  =(~ c)
    ?:  =(stone.turno stone:(need c))
      %.n
    $(i +(i))
  $(i +(i))
::
++  valid-column
  |=  turno=pick15-turno
  ^-  ?
  =+  i=0
  |-
  ?:  =(i 4)
    %.y
  =/  c=(unit player)  (~(get by game-board) [i +.spot.turno])
  ?.  =(~ c)
    ?:  =(stone.turno stone:(need c))
      %.n
    $(i +(i))
  $(i +(i))
::
++  valid-square
  |=  turno=pick15-turno
  ^-  ?
  =+  i=0
  =+  j=0
  |-
  ?:  =(i 4)
    %.y
  |-
  ?:  =(j 4)
    ^$(i +(i), j 0)
  =/  c=(unit player)  (~(get by game-board) [i j])
  ?.  =(~ c)
    ?:  =(stone.turno stone:(need c))
      %.n
    $(j +(j))
  $(j +(j))
::
++  step
  |=  [=spot =player]
  ^-  [outcome board]
  =.  game-board  (~(put by game-board) [spot player])
  [outcome-check game-board]
::
++  outcome-check
  ^-  outcome
  ?:  win-check
    %wins
  ?:(tie-check %tie ~)
::
++  win-check
  :: |=  stone=stone
  ^-  ?
  %+  lien  winning-rows
  |=  a=(list spot)
  ^-  ?
  =/  count  0
  |-  ^-  ?
  ?:  &(=(~ a) =(count 15))
    %.y
  ?~  a  %.n
  =/  c=(unit player)  (~(get by game-board) i.a)
  ?~  c
    %.n
  ?:  (gth (add count `@`stone:(need c)) 15)
    %.n
  $(a t.a, count (add count `@`stone:(need c)))
::
++  tie-check
  =(~(wyt in game-board) 9)
::
++  winning-rows
  ^-  (list (list spot))
  :~  ~[[%1 %1] [%2 %1] [%3 %1]]
      ~[[%1 %2] [%2 %2] [%3 %2]]
      ~[[%1 %3] [%2 %3] [%3 %3]]
      ~[[%1 %1] [%1 %2] [%1 %3]]
      ~[[%2 %1] [%2 %2] [%2 %3]]
      ~[[%3 %1] [%3 %2] [%3 %3]]
      ~[[%1 %3] [%2 %2] [%3 %1]]
      ~[[%1 %1] [%2 %2] [%3 %3]]
  ==
::
::  %helpers
::
::     (TODO: move to /===/lib)
::
+|  %helpers
::
++  get-icon
  |=  per=(unit player)
  ^-  tape
  ?~  per  " "
  (scow %u stone.u.per)
::
++  get-color
  |=  per=(unit player)
  ^-  tint
  ?~  per  *tint
  color.u.per
::
++  queue-to-list
  |=  queue=subscribers
  =/  count  1
  :-  %tan
  %-  flop
  :-  leaf+".............."
  |-  ^-  (list [%leaf tape])
  ?~  queue
    ~[leaf+".............."]
  =/  split-q  ~(get cola queue)
  ::  FIXME: previously this code:
  ::
  ::    =/  player  (need ~(top cola queue))
  ::    $(queue ~(nap cola queue) ... )
  ::
  ::    would replicate the rest of the queue as the head (?)
  ::    like this:
  ::    [%queue {[ze=~dopzod subs=[in=3 out=0]] [ze=~marzod subs=[in=4 out=0]]}]
  ::    [%head [~ u=[ze=~marzod subs=[in=4 out=0]]]]
  ::    [%rest [n=[ze=~marzod subs=[in=4 out=0]] l=~ r=~]]
  ::
  ::    idea: could be an issue with; ++ bal, balancing the tree
  ::    after a nap?
  ::
  ::    Solution: check %/lib/cola/hoon for a fix of the queue
  ::    and https://github.com/urbit/arvo/issues/1100 for comments
  ::
  :-  leaf+"{<count>}. {(cite:title ze.p:-:split-q)}"
  $(queue q:+:split-q, count +(count))
::
++  update-queue-head
  |=  [subs=subscribers head=remote-app]
  ^-  subscribers
  %-  ~(gas to `subscribers`~)
  :-  head
  |-  ^-  (list remote-app)
  ?~  subs  ~
  [(need ~(top cola subs)) $(subs ~(nap cola subs))]
::
++  remove-from-queue
  |=  [subs=subscribers head=remote-app]
  ^-  subscribers
  ::  we create a list of remote-apps and convert it
  ::  to a queue of subscribers
  ::
  %-  ~(gas to `subscribers`~)
  |-  ^-  (list remote-app)
  ?~  subs  ~
  ?:  =(ze.head ze:(need ~(top cola subs)))
    ::  we have found the subscription to cancel
    ::  and we skip it
    ::
    $(subs ~(nap cola subs))
  ::  we keep looking in the queue
  ::
  [(need ~(top cola subs)) $(subs ~(nap cola subs))]
::
:: ++  guest-bone
::   |=  [ze=ship =path]
::   ^-  bone
::   ::  $arvo-subscribers:
::   ::    list of who has sent us a %peer with a join wire
::   ::
::   =/  arvo-subs  (prey:pubsub:userlib path bol)
::   =+  (skim arvo-subs |=(a=[* ze=ship *] =(ze.a ze)))
::   ?~  -  !!
::   -.-
::
++  easter-egg
  ^-  (quip move _this)
  =^  edit  state.consol  (transmit-sole reset)
  [~[(effect mor+~[mor+falken det+edit])] this]
::
--
