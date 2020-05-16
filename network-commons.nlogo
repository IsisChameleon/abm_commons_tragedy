;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     G  U  I  D  E  L  I  N  E  S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  globals in uppercase = constants e.g. MAX-ON-BEST-PATCH
;;  variables in a procedures that start with _ ==> local variables only used in that procedure
;;  variables booleans ==> named with a ? at the end e.g. depleted?
;;  all % are between 0 and 1
;;
;;  local variables ==> _global
;; Useful doco:
;; on selecting an action based on a probability : https://stackoverflow.com/questions/41901313/netlogo-assign-variable-using-probabilities/41902311#41902311
;; on coding to detect overlapping of turtles : GasLab Circular Particles model by Wilensky on netlogo model library


extensions [ rnd table palette nw]
;;breed [villagers villager] ;; http://ccl.northwestern.edu/netlogo/docs/dict/breed.html
directed-link-breed [ friendships friendship ] ;; between villagers

globals
[
  ;; all these variables get their values in "initialize-globals".
  ;; values won't change over time
  ;; these values are used in the setup procedures

  PERCENT-BEST-LAND   ;
  MAX-ON-BEST-PATCH   ; maximum value of resource the best patch can hold
  PATCH-MIN-TO-REGROW ; need to leave at least % amount of the max-patch resource for this patch to regrow
  PATCH-REGROWTH-RATE ; % of max resource on patch that regrows every tick if over the min-to-regrow
  PATCH-DECAY-RATE    ;
  MAX-TURTLE-SIZE     ; used for visuals

  MIN-TURTLE-DISTANCE ; minimum patches a turtle has to stay away from others
  FIND-NEW-PLACE-PCT  ; percentage of neighboring turtles hungry that will make a turtle go to look for a new place
  MWF-TICKER-MAX
  FNP-TICKER-MAX

  MAX-TURTLE-VISION   ; how many patches ahead a human can see
  MIN-TURTLE-HUNGER   ; how many units of resource a human consumes each step to stay well
  MAX-TURTLE-HARVEST  ; maximum that a human can harvest during a tick
  MIN-TURTLE-HARVEST  ; minimum amount that a turtle is trying to consume each step
  FACTOR-DIV          ; weight of the amount of resource on the patch when the turtle, the bigger the less weight
                      ; e.g. if FACTOR DIV = 4  the amount of resource on the patch needs to be at least 4 times higher than the amount a turle can harvest to have an influence on the amount harvested
  MAX-TURTLE-MEMORY   ; how many items a turtle can remember in a list

  MAX-LINK-STRENGTH   ; maximum strength of the link between 2 turtles

  HFC-TICKER-START    ; %pct of friends hungry that kcik off the hungry friend count "distress ticker"
  HFC-TICKER-STOP     ; %pct of friends hungry that stop the ticker
  HFC-TICKER-MAX      ; max before an alert is raised


  PRL-TICKER-START    ;- THE TICKER starts ticking when total friends patch resource level drops below PRL-TICKER-START% of the maximum recorded PRL
  PRL-TICKER-STOP     ;- THE TICKER stops ticking when total friends patch resource level raise above PRL-TICKER-STOP% of the maximum recorded PRL
  PRL-TICKER-MAX      ;- when the ticker has been active for PRL-TICKER-MAX ticks, the alert is raised and turtle-group is asked to lower harvest

  INCREASE-PCT        ; pct increase when asked to harvest a bit more
  DECREASE-PCT        ; pct decrease when asked to harvest a bit less

  ;; (NOW A SLIDER) LINK-TRANSMISSION-DISTANCE ;  indicates how far away on the network information spreads, a value of zero means there's no communication
  ;; (NOW A SLIDER) DEBUG-RATE         ; proportion of agents for which the debugging is activeOW

  ;; these variables evolve with the simulation

  total-resource     ; total resource available summed over all the resource patches
  total-food-exchanged ; amount of resource given to hungry turtles
  debugging-agentset    ;  turtles that are followed by the debugging procedure when "follow agent-set switch" is true on interface

]
patches-own ;; this is the patches of resources
[
  ;; PATCH INTRINSIC PROPERTIES
  ;;============================
  ; patch charateristics that won't change over time

  regrowth-rate       ; % patch-max-resource that regrows each tick, between 0 and 1
  decay-rate          ; % patch-resource lost each tick
  min-to-regrow       ; percentage of patch-max-resource below which the patch won't regrow
                      ; all % are between 0 and 1
  patch-max-resource  ; the maximum amount of resource this patch can hold
  patch-id            ; uniquely identifies the patchs
  initial-patch-resource ; used to reset simulation to initial values

  ;; CURRENT STATUS AND AMOUNT OF REGROWTH
  ;;========================================
  ; patch characteristics that change over time

  patch-resource      ; the current amount of resource on this patch
  patch-regrowth      ; amount of regrowth this tick
  depleted?           ; indicate if a patch has been harvested too much and is depleted

]

turtles-own
[
  ;; TURTLE INTRINSIC PROPERTIES
  ;;============================
  ;;  charateristics that won't change over time
  turtle-vision            ; how many patches ahead a turtle can see
  turtle-hunger            ; how many resource the turtle needs to consume each step
  turtle-harvest           ; maximum that this turtle can harvest during a tick
  turtle-memory-size            ; size of a turtle's memory
  turtle-group             ; group of linked turtle by a link radius = LINK-TRANSMISSION-DISTANCE

  ;; TURTLE CURRENT PROPERTIES
  ;===========================
  ;; turtles characteristics that change over time

  ;; RELATED TO HARVEST
  turtle-resource                 ; the amount of resource that the turtle privately owns, it adds to it after harvesting
  turtle-current-harvest          ; amount that the turtle has decided to harvest
  current-actual-quantity-harvested ; quantity that the turtle has actually harvested this tick
  current-harvest-recommended-level  ; considering the min that the turtle is willing to harvest and the max that a turtle can harvest
                                     ; recommended harvest amount = min + (max - min) * current-harvest-recommended-level

  ;; MESSAGING & CONNECTIVITY
  ;;=========================
  turtle-test-hub                 ; count of how many messages that turtle has received when testing for hubs

  ;; MOVE
  ;;=====

  new-place                   ; new place the turtle is heading towards
  move-friend                 ; friend the turtle is moving to
  move-with-friend-ticker     ;
  find-new-place-ticker       ;

  ;; MEMORY AND STRATEGY, ALERTING LEVELS
  ;;=====================================
  turtle-hunger-level             ; each tick the turtle is hungry consecutively it adds 1, each tick the turtle is not hungry it removes 1 (with a min of zero)

  hungry?                     ; set to true when a turtle cannot consume "turtle-hunger" amount of resource in one tick
  hungry-friends-count        ; amount of friends that have told they are hungry
  hfc-ticker                  ; start counting every tick hungry-friends-count is above a certain treshold HFC-TICKER-START
                              ; stop counting when number of hungry friends HFC-TICKER-STOP
                              ; alert people when ticker reached HFC-TICKER-MAX to consume more
  prl-ticker                  ; a ticker that increments by 1 each tick when total resources found on all friends patches (turtle-group-and-me) trigger alert levels
  current-prl                 ; calculated total amount of resources currently available on the patches where all the group (turtle-group-and-me) is
  max-prl                     ; maximum amount of of resource ever seen on the patches of myself and all my friends (=turtle-group-and-me), prl = Patch Resource Level:

  ;; OBSERVE WORLD, MOVEMENT
  ;;==========================
  ;; variables valid for one tick, set in observe-world
  random-visible-patch
  random-neighboring-patch
  random-visible-turtle
  best-visible-patch    ;; identify 1 patch within the vision that has the max resource (for move decision)
  best-neighboring-patch ;; identify 1 patch just neighbor that has the max quantity of resource (for harvesting)
  best-visible-turtle    ;; identify 1 turtle or None (with max link strength)

  ;; NOT USED
    turtle-memory                   ; turtle's memory  ;; NOT USED
    has-moved?                  ; set to true when a turtle has move. reset to false at the end of Go
  ;; turtle-recommended-pct-harvest  ;
  ;; harvest-knowledge  ; knowledge they use for harvesting
                     ; list element 0 :  known-best-patch or quantity of resource on the best patch the turtle knows
                     ; list element 1 :  % of the best quantity they know that they will leave on patch
  ;; harvest-decision   ; probability to make the following decision
                     ; "harvest-max-possible" probability:  1 - harvest-decision
                     ; "harvest-using-knowledge" probability: harvest-decision

  ;; current-actual-quantity-harvested
]

links-own
[
  strength
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     D   E   B   U   G
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to debugging [ proc-name list-values ]
  if DEBUG = True [
    ifelse debugging-agentset? = True [
      if self != nobody
      and any? debugging-agentset
      [
        if member? self debugging-agentset [
         output-type but-last list-values
          output-show last list-values
        ]
      ]
    ][
      ;;if  proc-name = proc-name-chooser or proc-name-chooser = "all" or proc-name = "subproc" [
        if random-float 1 < DEBUG-RATE [
          output-type but-last list-values
          output-show last list-values
        ]
      ;;]
    ]
  ]
end

to debugging-obs [ list-values ]
  if DEBUG = True [
    if random-float 1 < DEBUG-RATE [
       output-type but-last list-values
      output-show last list-values
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     S   E   T   U   P
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to initialize-globals

  ;; turtles intrisic properties

  set MAX-TURTLE-VISION 8
  set MIN-TURTLE-HUNGER 2
  set MAX-TURTLE-HARVEST 5
  set MIN-TURTLE-HARVEST 2
  set MAX-TURTLE-MEMORY 5

  ;; patches

  set PERCENT-BEST-LAND 0.06
  set MAX-ON-BEST-PATCH 100
  set PATCH-MIN-TO-REGROW 0.5  ;; need to leave at least % amount of the max-patch resource for this patch to regrow
  set PATCH-REGROWTH-RATE 0.15  ;; % of max resource on patch that regrows every tick if over the min-to-regrow
  set PATCH-DECAY-RATE 0.2

  ;; harvest

  set FACTOR-DIV 4

  ;; movement

  set MIN-TURTLE-DISTANCE 2    ;; one turtle per patch
  set FIND-NEW-PLACE-PCT 0.1   ;; treshold for the amount fo hungry turtles that trigger a move
  set MWF-TICKER-MAX 20        ;; turtle tries to reach friend for max 50 ticks
  set FNP-TICKER-MAX 20        ;; turtle tries to reach new place for max 50 ticks

  ;; communication

  set MAX-LINK-STRENGTH 10     ;;
  set LINK-TRANSMISSION-DISTANCE 1 ;; indicates how far away on the network information spreads, a value of zero means there's no communication

  ;; adaptive behavior

  set HFC-TICKER-START 0.5
  set HFC-TICKER-STOP 0.3
  set HFC-TICKER-MAX 10
  set PRL-TICKER-START 0.5
  set PRL-TICKER-STOP 0.7
  set PRL-TICKER-MAX 10
  set INCREASE-PCT 0.1
  set DECREASE-PCT 0.1

  ;; reporting variables
  ;; turtles -->
  set total-food-exchanged 0

  ;; visuals
  set MAX-TURTLE-SIZE 2

  ;; debugging
  set DEBUG-RATE 0.05
  set debugging-agentset no-turtles
end

to initialize-debugging
  if debugging-agentset? = true [
    set debugging-agentset n-of debugging-agentset-nb turtles
  ]
end

to setup
  clear-all
  initialize-globals
  setup-patches
  set-default-shape turtles "person"
  setup-network
  setup-turtles
  set-turtle-test-hub      ;; needs to happen after setup-turtles
  initialize-debugging
  save-setup
  reset-ticks
end

to reset-simulation
  ask patches [
    set patch-resource initial-patch-resource
    set patch-regrowth  0     ; amount of regrowth this tick
    set depleted? false
    set-patch-color
  ]
  ask turtles [
   setup-each-turtle
   set-turtle-color
   set label ""
  ]
  ask links [
    ifelse show-link?  [ show-link ] [ hide-link ]
  ]
  reset-ticks
  clear-all-plots

end

to setup-turtles
  ;; the rest of the turtle setup is done in the setup-network
  ;; by the procedure setup-each-turtle
  ;; this needs to be set-up after the network is done
  ask turtles [
    set-turtle-group LINK-TRANSMISSION-DISTANCE
    set-turtle-color
  ]
end

to setup-each-turtle
  setxy random-xcor random-ycor
  set turtle-hunger MIN-TURTLE-HUNGER
  set turtle-vision MAX-TURTLE-VISION
  set turtle-harvest MAX-TURTLE-HARVEST
  set current-harvest-recommended-level INIT-HARVEST-LEVEL ; initial recommended harvest level
  set hfc-ticker 0
  set prl-ticker 0
  set move-with-friend-ticker 0
  set find-new-place-ticker 0
  set max-prl 0
  set turtle-resource 0
  set current-actual-quantity-harvested 0
  set hungry? false
  set has-moved? false
  set-turtle-memory
end

to set-turtle-memory
  set turtle-memory-size MAX-TURTLE-MEMORY
  set turtle-memory table:make
  memorize-current-patch-resource-level
end

to set-turtle-size-backpack
    let _max [ turtle-resource] of max-one-of turtles [ turtle-resource ]
    let _min [ turtle-resource] of min-one-of turtles [ turtle-resource ]
    ifelse ( _max - _min ) > 0 [
      set size (turtle-resource - _min) * MAX-TURTLE-SIZE /  ( _max - _min )  + 1
      set size max list size 1
      set size min list size MAX-TURTLE-SIZE
    ][
      set size 1
    ]
end

to set-turtle-size-connectivity
    let _min [ turtle-test-hub ] of min-one-of turtles [ turtle-test-hub ]
    let _max [ turtle-test-hub ] of max-one-of turtles [ turtle-test-hub ]
    ifelse ( _max - _min ) > 0 [
      set size (turtle-test-hub - _min ) * MAX-TURTLE-SIZE / ( _max - _min )  + 1
      set size max list size 1
      set size min list size MAX-TURTLE-SIZE
    ][
      set size 1
    ]
end

to reset-size
  ask turtles [
    set size 1
  ]
end

to set-color
  ask turtles [
    set-turtle-color
  ]
end

to set-turtle-color
  if hungry? = true [ set label "hungry" ]
  if color-chooser = "turtle-backpack" [
    set-turtle-color-backpack
    set-turtle-size-backpack
  ]
  if color-chooser = "turtle-connectivity" [
    let _min [ turtle-test-hub ] of min-one-of turtles [ turtle-test-hub ]
    let _max [ turtle-test-hub ] of max-one-of turtles [ turtle-test-hub ]
    set-turtle-color-by-hub  _min _max
    set-turtle-size-connectivity
  ]
  if color-chooser = "turtle-resource-ticker" [
    if prl-ticker = 0 [
      set color brown
      set size 1
      set label ""
    ]
    if prl-ticker > 0 and prl-ticker < PRL-TICKER-MAX [
      ;; BROWN TO bright orange
      ;; brown : 140, 66, 22
      ;; bright orange : 250, 129, 0
      let _rgb-color-list [[140 66 22] [250 129 0]]
      set color palette:scale-gradient _rgb-color-list prl-ticker 1 10
      set size  floor ( (prl-ticker + 1) / 3 )
    ]
    if prl-ticker = PRL-TICKER-MAX [
      set color white
      set label "ALERT"
    ]
  ]
  if color-chooser = "turtle-hunger-ticker" [
    if hfc-ticker = 0 [
      set color 102   ;;dark blue
      set size 1
      set label ""
    ]
    if hfc-ticker > 0 and hfc-ticker < HFC-TICKER-MAX [
      ;; dark blue TO bright pink
      ;; dark blue : 13, 37, 158
      ;; bright pink : 228, 197, 252
      let _rgb-color-list [[13 37 158] [228 197 252]]
      set color palette:scale-gradient _rgb-color-list hfc-ticker 1 10
      set size floor ( (hfc-ticker + 1) / 3 )
      set size max list size 1
      set size min list size MAX-TURTLE-SIZE
    ]
    if hfc-ticker = HFC-TICKER-MAX [
      set color white
      set label "ALERT"
    ]
  ]
end

to set-turtle-color-backpack ;;turtle proc
  let _rgb-color-list [[230 2 2 ] [255 247 20]]   ;; red to yellow
  let _max [ turtle-resource ] of max-one-of turtles [ turtle-resource ]
  let _min [ turtle-resource ] of min-one-of turtles [ turtle-resource ]
  set color palette:scale-gradient _rgb-color-list turtle-resource _min _max
end

to set-turtle-color-by-hub [ min-value max-value ] ;; turtle proc
  ; bright yellow = 255, 252, 94
  ; bright pink = 255, 51, 245     248, 5, 252
  ; dark pink = 46, 1, 44
  let _rgb-color-list [[13 0 13] [248 5 252]]
  set color palette:scale-gradient _rgb-color-list turtle-test-hub min-value max-value
  ifelse max-value > 0 [
    set size floor ( ( turtle-test-hub - min-value ) * MAX-TURTLE-SIZE /  ( max-value - min-value ) )
    set size min list size 1
  ][
    set size 1
  ]
end

to set-turtle-group [ link-distance ] ;; turtle-proc
  ifelse  link-distance > 0 [
    set turtle-group other nw:turtles-in-radius link-distance                ;; this will return all the turtles that are LINK-TRANSMISSION-DISTANCE  - self
  ][
    set turtle-group no-turtles
  ]
end

to-report turtle-group-and-me ;; turtle proc                                 ;; for cases when you want turtle-group to include self, use "turtle-group-and-me"
  report (turtle-set turtle-group self)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     S   E   T   U   P    P  A  T  C  H  E  S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-patches
  ;; SET CHARACTERISTICS that don't change over time
  let _patch-id 0
  ask patches [
    set min-to-regrow PATCH-MIN-TO-REGROW  ;; need to leave at least % amount of the max-patch resource for this patch to regrow
    set regrowth-rate PATCH-REGROWTH-RATE  ;; % of max resource on patch that regrows every tick if over the min-to-regrow
    set decay-rate PATCH-DECAY-RATE    ;;
    set patch-id _patch-id
    set _patch-id _patch-id + 1

  ;; SET INITIAL RESOURCE LEVEL
  ;; inspiration from resource-harvest.nlogo

  ;; a certain percentage of patches will be the best

    set patch-max-resource 0
    if (random-float 1) <= PERCENT-BEST-LAND [
      set patch-max-resource MAX-ON-BEST-PATCH
      set patch-resource patch-max-resource
    ]
  ]
  ;; set up some patches that will diffuse 25% of their max resource around them
  repeat 5 [
    ask patches with [patch-max-resource != 0] [
      set patch-resource patch-max-resource
    ]
    diffuse patch-resource 0.25
  ]

  repeat 10 [
    diffuse patch-resource 0.25
  ]
  ask patches [
     set patch-resource floor patch-resource   ;; round resource levels to whole numbers
     set patch-max-resource patch-resource      ;; initial resource level is also maximum
     set-patch-color
     set depleted? false
     set initial-patch-resource patch-resource    ;; saving the initial configuration
  ]

end

to set-patch-color ;; patch proc
  ;; colour scale from 0 to the best patch possible
  set pcolor scale-color green patch-resource 0 MAX-ON-BEST-PATCH
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     F  I  N  D   H  U B S   & T E S T   C O M M S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to highlight-hubs [ some-turtles ]
  ;; !!! the results depends on the value of "LINK-TRANSMISSION-DISTANCE"
  ;; when LINK-TRANSMISSION-DISTANCE = 1 _min and _max need to be = min deg and max degree of the network
  ;; how to check : click highlight-hub in the interface then use the observer window
  ;; observer> show [ turtle-test-hub ] of max-one-of turtles [ turtle-test-hub ]

  ask turtles [
    ;; recalculate the groups of turtles in case the LINK-TRANSMISSION-DISTANCE has changed
    set-turtle-group LINK-TRANSMISSION-DISTANCE
    set color black
    set turtle-test-hub 0
  ]
  ask some-turtles [
    ask turtle-group [
      set turtle-test-hub turtle-test-hub + 1
    ]
  ]
  let _min [ turtle-test-hub ] of min-one-of some-turtles [ turtle-test-hub ]
  let _max [ turtle-test-hub ] of max-one-of some-turtles [ turtle-test-hub ]
  debugging-obs (list "HIGHLIGHT-HUBS: _min " _min "-max : " _max)

  ifelse some-turtles = turtles [
    ask turtles [
      set-turtle-color-by-hub _min _max
      set-turtle-size-connectivity
    ]
  ][
    ask some-turtles [
      set color white
      ask turtle-group [
        set color pink
      ]
    ]
  ]

  ;; recalculate turtle-test-hub for all turtles

  ask turtles [
    set turtle-test-hub 0
  ]
  ask turtles [
    ask turtle-group [
      set turtle-test-hub turtle-test-hub + 1
    ]
  ]
end

to set-turtle-test-hub

  ;; recalculate turtle-test-hub for all turtles

  ask turtles [
    set turtle-test-hub 0
  ]
  ask turtles [
    ask turtle-group [
      set turtle-test-hub turtle-test-hub + 1
    ]
  ]
end

;;to reset-hub
;;  ask turtles [
;;   set-turtle-color
;;  ]
;; end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     S   A   V   E    &&   R  E  L  O  A  D
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to save-setup
  ; procedure to save all setup parameters
  save-network    ;; save network, ideally with strength value (initial version  can be only links)
  save-patches    ;; save each patch initial configuration
  save-parameters ;; to save turtles parameters like nb-villagers, turtle-visino, ....
end

to save-network
end

to save-patches
end
to save-parameters
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     G   O      P   R   O   C
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  reset-globals-before-go

  ask links [
    ifelse show-link?  [ show-link ] [ hide-link ]
  ]

  ask turtles [
    set label ""
    observe-world    ;; set a few variables like best-visible-turtle, best-visible-patch
    move
    observe-world
    harvest           ;; for each turtle will update the turtle-resource variable based on what they have harvested
    consume
    memorize-and-strategy
    set-turtle-color
    reset-alert
    ;; change-strategy
  ]

  ask patches [
    regrow
  ]


  ifelse total-resource-reporter = 0 ;; if no more resources stop
  [ stop ]
  [ tick ]

end

to regrow
  if regrowth-chooser = "with-depletion" [
    regrow-with-depletion
  ]
  if regrowth-chooser = "always-regrow" [
    regrow-no-depletion
  ]
end

to regrow-with-depletion ;; patch proc
  ;; only regrow if less than the max of resources AND it's not depleted

  let _depleted?-old depleted?
  let _patch-resource-old patch-resource

  if patch-resource <   (min-to-regrow * patch-max-resource) and depleted? = false
  [set depleted? true]

  if ( patch-resource < patch-max-resource and depleted? = false)[


    set patch-resource patch-resource + regrowth-rate * patch-max-resource
    set patch-resource min list patch-resource patch-max-resource

    debugging  "regrow" (list "REGROW: patch resource : " _patch-resource-old " - patch-max-resource : "
      patch-max-resource " - regrowth rate : " regrowth-rate " - new patch resource : " patch-resource )

    set-patch-color
  ]

  if depleted? = true   [
    if patch-resource > 0
    [
      set patch-resource patch-resource - decay-rate * patch-resource
      set patch-resource max list patch-resource 0
    ]

    debugging "regrow" (list "REGROW:depleted patch=" patch-resource "-lost=" (decay-rate * patch-resource) " resources.")
  ]

  set patch-regrowth ( patch-resource - _patch-resource-old )
end

to regrow-no-depletion ;; patch proc
  let _patch-resource-old patch-resource

  if ( patch-resource < patch-max-resource and  patch-resource > 0)[

    set patch-resource patch-resource + regrowth-rate * patch-max-resource
    set patch-resource min list patch-resource patch-max-resource

    debugging  "regrow" (list "REGROW: patch resource : " _patch-resource-old " - patch-max-resource : "
      patch-max-resource " - regrowth rate : " regrowth-rate " - new patch resource : " patch-resource )

    set-patch-color
  ]

  set patch-regrowth ( patch-resource - _patch-resource-old )
end

to reset-globals-before-go ;; observer proc
    set total-food-exchanged 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     O   B  S  E  R  V  E     W  O  R  L  D
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to observe-world ;; turtle proc
  ;; this procedure is called before and after the turtle move
  set best-visible-patch max-one-of patches in-radius turtle-vision [ patch-resource ]  ;;; e.g. show max-one-of patches [count turtles-here]  ask patches in-radius 3
  set random-visible-patch one-of patches in-radius turtle-vision
  set best-neighboring-patch max-one-of patches at-points [[1 0] [0 1] [0 0] [-1 0] [0 -1]] [ patch-resource ] ;; best patch for harvesting with max-resource
  set random-neighboring-patch one-of patches at-points [[1 0] [0 1] [0 0] [-1 0] [0 -1]] ;; random neighbboring patch
  set best-visible-turtle max-one-of turtles in-radius turtle-vision  [ turtle-resource ] ;;
  set random-visible-turtle one-of link-neighbors in-radius turtle-vision

  debugging "observe-world" (list "OBSERVE-WORLD:best-neighboring-patch=" best-neighboring-patch "-best-visible-patch=" best-visible-patch)
  debugging "observe-world" (list "OBSERVE-WORLD:best-visible-turtle=" best-visible-turtle "-random-visible-turtle=" random-visible-turtle)

end

to-report get-link-strength-with [ a-turtle ] ;; turtle proc, reports the strength of the link between current turtle and another turtle
  ifelse a-turtle != nobody and
         link [ who ] of self [ who ] of a-turtle != nobody [
    debugging "subproc" ( list "GET-LINK-STRENGTH-WITH: a-turtle=" a-turtle "-strength:" [ strength ] of link [ who ] of self [ who ] of a-turtle )
    report [ strength ] of link [ who ] of self [ who ] of a-turtle
  ][
    report 0
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     M   O   V   E
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move  ;; turtle proc

  ;; 3 POSSIBLE DECISIONS : "move-alone" "move-with-friend" "stay"
  ;; "move-with-friend" movement should be inspired of flocking birds and ants
  ;; assuming each turtle only move "1" square each tick? (?)
  ;; _decide reporter variable is a string which will contain one of those values : "move-alone", "move-with-friend", "stay"

  let _decision decide-move


  if ( _decision = "stay" )[
    stay
  ]
  if (_decision = "move-with-friend")[
    move-with-friend move-friend ;; [ turtle ]
    set has-moved? true
  ]
  if (_decision = "move-alone")[
    move-alone ;; [ patch ]
    set has-moved? true
  ]
  if (_decision = "find-new-place")[
    find-new-place new-place ;; [ patch ]
    set has-moved? true
  ]
  if (_decision = "random")[
    move-at-random
    set has-moved? true
  ]
end

to-report decide-move
  ;; This procedure helps the turtle decide whether to stay, move alone or with friend
  ;; without a friend, probability to stay or move is propertional on the expected yield of resource in each considered patch
  ;; the yield of resource for a patch is calculated taking into account the turtle harvest strategy, i.e how much a turtle is willing to harvest on the patch
  ;; with a friend the probability to move with a friend is propertional to the strength of that bond, up to a max of 100% moving with the friend
  ;; if that friend has the max strength link
  ;; the probabilities for moving alone or staying are scaled down to "make room" for the moving with friend probability

  ;; if turtles already following a friend

  let _decision ""

  if move-with-friend-ticker > 0 AND
     move-with-friend-ticker < MWF-TICKER-MAX AND
     distance move-friend > 3
  [
    set _decision "move-with-friend"
    set move-with-friend-ticker move-with-friend-ticker + 1
    report _decision
  ]

  if find-new-place-ticker > 0 AND
     find-new-place-ticker < FNP-TICKER-MAX AND
     distance new-place > 3
  [
    set _decision "find-new-place"
    set find-new-place-ticker find-new-place-ticker + 1
    report _decision
  ]

  if move-with-friend-ticker >= MWF-TICKER-MAX
  [
    set move-with-friend-ticker 0
  ]

  if find-new-place-ticker >= FNP-TICKER-MAX
  [
    set find-new-place-ticker 0
  ]

  let _quantity_harvest_neighbor decide-harvest best-neighboring-patch
  let _quantity_harvest_visible decide-harvest best-visible-patch
  debugging "move" (list "DECIDE-MOVE:_quantity_harvest_neighbor:" _quantity_harvest_neighbor "_quantity_harvest_visible :" _quantity_harvest_visible)
  let _yield_stay _quantity_harvest_neighbor / turtle-harvest        ;; if the turtle stay it will be able to harvest a certain % of max quantity it can carry
                                                                     ;; = quantity that it is happy to harvest taking into account the limits of the patch / max quantity it can carry
  let _yield_move_alone _quantity_harvest_visible / turtle-harvest

  ;; initialize probabilities
  let _prob_move_alone 1
  let _prob_stay 0
  let _prob_move_with_friend  0

  debugging "move" (list "DECIDE-MOVE:yield_stay :" _yield_stay "-yield_move_alone :" _yield_move_alone)

  ;; when there is no friend around the chance to move is proportional to the amount there is to harvest in each case, when you stay or what you see
  ;; i.e. assuming the amount of resource to collect is the same, the turtle will have equal chances to go or to stay
  if (_yield_stay + _yield_move_alone) != 0 [
       set _prob_stay  _yield_stay * ( 1 / (_yield_stay + _yield_move_alone) )
       set _prob_move_alone  _yield_move_alone * ( 1 / (_yield_stay + _yield_move_alone) )
  ]

  if best-visible-turtle != nobody [
    ;; accessing strength of link with best-visible-turtle
    let _strength get-link-strength-with ( best-visible-turtle )

    ;; probability to move with friend is proportional to link strength with best visible friend
    let _strength_scaling 1 / MAX-LINK-STRENGTH
    set _prob_move_with_friend _strength_scaling * _strength

    ;; scale down probabilities for moving  alone or staying to "make room" for move with friend
    ;; sum of all probabilies need to be = 1

    let _prob_scaling ( 1 - _prob_move_with_friend )
    set _prob_stay _prob_stay * _prob_scaling
    set _prob_move_alone _prob_move_alone * _prob_scaling
  ]

  let _actions ["stay" "move-alone" "move-with-friend" ]
  let _probs (list  _prob_stay _prob_move_alone _prob_move_with_friend)
 ;; debugging "move" (list "DECIDE-MOVE:stay:move-alone:move-with-friend" _prob_stay ":" _prob_move_alone ":" _prob_move_with_friend)

  set _decision decide _probs _actions


  ;; IF TOO MANY HUNGRY SCRAP THIS i'M GOING ELSEWHERE
  ;;  OR TOO MANY TURTLES
  let _turtles_1 turtles in-radius turtle-vision with [ hungry? = true ]
  let _turtles_2 turtles in-radius turtle-vision
  let _max count patches in-radius turtle-vision
  let _me self
  let _new-place one-of patches
  ;; if count _turtles_1 > ( FIND-NEW-PLACE-PCT * _max )[
  if count _turtles_1 >= 1
   or count _turtles_2 > ( 0.8 * _max )
  [
    debugging "move" (list "DECIDE-MOVE FIND NEW PLACE: find new place " _new-place)
    set _decision "find-new-place"
    set new-place _new-place
  ]

  if  _decision = "move-with-friend" [
    set move-with-friend-ticker 1
    set move-friend best-visible-turtle
  ]
  if  _decision = "find-new-place" [
    set find-new-place-ticker 1
    set new-place  _new-place
  ]

  report _decision
end


to stay
end

to find-new-place [ a-patch ]
  face a-patch
  fd MIN-TURTLE-DISTANCE
  let _loop 0
  while [ any? other turtles-here and _loop < 10] [
    reposition
    set _loop _loop + 1
  ]
  set find-new-place-ticker find-new-place-ticker + 1
end

to move-with-friend [ friend ]
  ;; TODO : move in the direction of friend
  debugging "move" (list "MOVE-WITH-FRIEND:best-visible-turtle " best-visible-turtle)
  ifelse friend  != nobody
  [
    face friend
    fd MIN-TURTLE-DISTANCE
    let _loop 0
    while [ any? other turtles-here and _loop < 10] [
      reposition
      set _loop _loop + 1
    ]
  ][
    move-alone
  ]
  set move-with-friend-ticker move-with-friend-ticker + 1
end

to move-alone ;; [ patch-to-move-to ]
  ;; move towards the patch-to-move-to
  debugging "move" (list "MOVE-ALONE:best-visible-patch" best-visible-patch )
  face best-visible-patch
  fd MIN-TURTLE-DISTANCE
  let _loop 0
  while [ any? other turtles-here and _loop < 10] [
    reposition
    set _loop _loop + 1
  ]
end

to move-at-random  ;; turtle proc
  debugging "move" (list "MOVE-AT-RANDOM:random-neighbouring-patch" random-neighboring-patch)
  move-to random-neighboring-patch
  while [ any? other turtles-here ] [ move-at-random ]
end

;;to-report detect-overlapping
  ;; in-radius is used to improve speed, as suggested in GasLab Circlular Particles model
  ;;report any? other turtles in-radius turtle-vision with [distance myself < MIN-TURTLE-DISTANCE]
;;end

to reposition
  move-to one-of neighbors
end

;;to reposition2 [ target ] ;;; STARTED NOT FINISHED : IDEA MOVE TO NEIGHTBOUR CLOSED TO TARGET (TARGET =A -TURTLE OR A-PATCH)
;;  move-to one-of neighbors min-one-of distance [ target ]
;; end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     M  E  S  S  A  G  E  S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to harvest-a-bit [ action some-turtles percentage ]  ;; turtle proc
  debugging "message" (list "HARVEST-A-BIT " action " by pct " percentage " for # " count some-turtles)
  let _turtle-current-harvest-request turtle-current-harvest
  ask some-turtles [
    if  action = "more" [
        ;; turtle will increase harvesting up to the max they can harvest (turtle-harvest)
        debugging "message" ( list "HARVEST-A-BIT " action ": current harvest request: " _turtle-current-harvest-request)
        set _turtle-current-harvest-request min list (turtle-current-harvest + percentage * turtle-current-harvest) turtle-harvest
        debugging "message" ( list "HARVEST-A-BIT " action ": amount requested to add:" (percentage * turtle-current-harvest) "-new harvest request: " _turtle-current-harvest-request)
    ]
    if action = "less" [
        debugging "message" ( list "HARVEST-A-BIT " action ": current harvest request: " _turtle-current-harvest-request)
        set _turtle-current-harvest-request max list (turtle-current-harvest - percentage * turtle-current-harvest) 0
        debugging "message" ( list "HARVEST-A-BIT " action ": amount requested to subtract:" (percentage * turtle-current-harvest) "-new harvest request: " _turtle-current-harvest-request)
    ]
    ;; at the moment we consider that the turtle is going to "obey"
    ;; FUTURE : in the improvments we can get the turtle to do what it's told in proportion to the strength
    ;; of the link between the turtle and the originator of the message
    set turtle-current-harvest _turtle-current-harvest-request
  ]
end

to message-im-hungry [ some-turtles ]
  ask some-turtles [
   set hungry-friends-count hungry-friends-count + 1
   debugging "message" (list "IM-HUNGRY: One of my friend is hungry bringing the count up to "  hungry-friends-count)
  ]
end

to message-im-not-hungry-anymore [ some-turtles ]
  ask some-turtles [
    set hungry-friends-count max list ( hungry-friends-count - 1 ) 0
  ]
end

to-report turtles-that-listen-to-me [ a-turtle radius ]
    ;; reports an agentset of turtles that are linked to a-turtle by "radius" nodes
    ;; e.g if radius is zero returns a-turtle
    ;; if radius is 1 returns all turtles that are linked directly to that turtle
    ;; if radius is 2 returns all turtles that are 1  or 2 links away from a-turtle
    ;; let _turtles ...
    ;; report _turtles
  if radius = 0 [
    report nobody
  ]
  if radius = 1 [
    report link-neighbors
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     H   A   R   V   E   S   T
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




to-report decide-harvest-sustainable [ a-patch ]  ;; turtle proc

  ;; the turtle only harvest what she needs to eat + a little bit to cope with time where she is on an empty patch

  let _turtle-minimum-sustainable ( turtle-hunger +  ( MIN-RSC-SAVING-PCT * turtle-hunger ))
  let _turtle_minimum-sustainable min list _turtle-minimum-sustainable turtle-harvest
  let _quantity-harvested min list _turtle-minimum-sustainable [ patch-resource ] of a-patch

  debugging "harvest" (list "DECIDE-HARVEST-SUSTAINABLE:_decision " _quantity-harvested " on patch " a-patch " containing this amount of resource " [ patch-resource ] of a-patch )
  report _quantity-harvested
end



to-report decide-harvest-between-min-and-max [ a-patch ]
  let _patch-current [ patch-resource ] of a-patch
  let _min min list MIN-TURTLE-HARVEST _patch-current         ;; MIN-TURTLE-HARVEST = what's the minimum a turtle is willing to try harvest each step
  let _max min list turtle-harvest _patch-current

  ;; current-harvest-recommended-level is a percentage that situates the recommended amount to harvest
  ;;  e.g. if max -min = 10
  ;; and current level recommended = 0.2
  ;; current level recommended to harvest = min + 0.2 * (max -min )
  ;; if current level = 1 : turtle will aim to consume min + (max -min ) ==> max (=turtle-harvest)
  ;; if current level = 0 : turtle will aim to consume min = MIN-TURTLE-HARVEST
  ;; this is weighted by _factor / 4 - to include the amount of resource on the patch - which means if the patch contains more than 4 times more resource than what the turtle can possibly
  ;; harvest in one tick, then the amount of harvest is going to be increase by that proportion
  ;; FACTOR-DIV = 4

  let _factor _patch-current / turtle-harvest

  let _recommended-harvest ( _min + (_max - _min ) * current-harvest-recommended-level * _factor / FACTOR-DIV )
  debugging "harvest" (list "DECIDE-HARVEST-BETWEEN-MIN-AND-MAX: current patch resource: " _patch-current "-min: " _min "-max:" _max "-factor: " _factor "-harvest recommended " _recommended-harvest)

  let _quantity-harvested _recommended-harvest

  report _recommended-harvest

end



to-report decide-harvest [ a-patch ]
  ifelse adaptive-harvest? = true [
    report decide-harvest-between-min-and-max a-patch
  ][
    report decide-harvest-sustainable a-patch
  ]
end


to harvest ;; turtle proc
  ;; TODO
  ;; identify richest neighbouring patch (amongst 5 patches,  4 patches around the turtle and one where turtle is)
  ;; decide how much to harvest (options : harvest-max-possible for a human, harvest-%-max-resource-on-that-patch)

  ;;let _quantity-harvested turtle-harvest         ;; TODO : change _quantity-harvested based on turtle decision
  let _quantity-harvested decide-harvest best-neighboring-patch   ;; decide how much the turtle is prepared to harvest on the patch here
  let _actual-quantity-harvested _quantity-harvested

  ;;debugging (list "HARVEST:About to harvest "  _quantity-harvested " on best neighboring patch  " best-neighboring-patch "-currently in backpack: " turtle-resource  )

  ask best-neighboring-patch [
    let _patch-resource-old patch-resource
    set _actual-quantity-harvested min list _quantity-harvested patch-resource ;; we cannot harvest more than what there is in the patch
    if ( patch-resource > 0 ) [
      set patch-resource patch-resource - _actual-quantity-harvested ;; harvesting
      set patch-resource max list patch-resource 0  ;; don't harvest below zero
      set-patch-color
    ]
    debugging-obs (list "HARVEST:best neighboring patch resource was " _patch-resource-old "-now is " patch-resource "-qty harvested=" _actual-quantity-harvested)
  ]

  set turtle-resource turtle-resource + _actual-quantity-harvested
  set current-actual-quantity-harvested _actual-quantity-harvested
  debugging "harvest" (list "HARVEST: After harvest turtle backpack contains " turtle-resource )

  ;; report _actual-quantity-harvested
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;            C   O   N   S   U   M   E             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; turtle will eat from her "backpack" (turtle-resource) or ask a friend or be hungry

to consume  ;; turtle procedure, turtule consumes resources
  let _turtle-actual-consume min list turtle-hunger turtle-resource
  set turtle-resource turtle-resource - _turtle-actual-consume

  ifelse _turtle-actual-consume < turtle-hunger [
    let _hunger turtle-hunger - _turtle-actual-consume
    ;; ask for food to the one of the linked turtles with the most food in the backpack
    ;; parameter 1 : the turtle to ask, parameter 2 : the amount of food requested
    let _friend-with-more-food max-one-of turtle-group [ turtle-resource ]
    let _food ask-for-food  _friend-with-more-food _hunger
    ;; capture the amount of food given to report the amount of food given every tick
    ;; total-food-exchanged is reset to 0 each tick
    set total-food-exchanged total-food-exchanged + _food
    debugging "consume" (list "CONSUME: Before asking for food _hunger=" _hunger "-received food from friend: " _food)
    set _hunger _hunger - _food
    if _hunger > 0 [
      if hungry? = false [
        message-im-hungry turtle-group
      ]
      set hungry? true
      set turtle-hunger-level turtle-hunger-level + 1
      debugging "consume" (list "CONSUME: turtle hunger level + 1! " turtle-hunger-level)
    ]
  ][
    set turtle-hunger-level max list (turtle-hunger-level - 1) 0
    if hungry? = true and turtle-hunger-level = 0 [
      set hungry? false
      message-im-not-hungry-anymore  turtle-group
    ]
    debugging "consume" (list "CONSUME: turtle hunger level -1! " turtle-hunger-level)
  ]
  debugging "consume" (list "CONSUME: turtle ate "  _turtle-actual-consume "-turtle has left in her backpack=" turtle-resource "-is hungry?=" hungry?)
end

to-report ask-for-food [ a-turtle quantity ]
  ;; For now if the turtle requested has food it will give it
  ;; FUTURE : the probability to give is related to the strength of the bond between the 2 turtles
  if a-turtle = nobody [
    report 0
  ]

  let _available min list quantity [ turtle-resource] of a-turtle
  ask a-turtle [
    debugging "consume" (list "ASK-FOR-FOOD: Turtle being asked for food has " _available " quantity: ")
    set turtle-resource turtle-resource - _available
  ]
  report _available
  ;; ask neighboring turtles for food, i.e ask best-visible-friend
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    M E M O R I Z E & S T R A T E G Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to reset-alert  ;; turtle proc
  if hfc-ticker = HFC-TICKER-MAX [
    set hfc-ticker 0
  ]
  if prl-ticker = PRL-TICKER-MAX [
    set prl-ticker 0
  ]
end

to memorize-and-strategy ;; turtle proc
  ;; memorize-current-patch-resource-level
  memorize-hungry-friends-count
  memorize-patches-resource-of-my-friends
end

to memorize-patches-resource-of-my-friends
  debugging "adaptive" (list "MEMORIZE-PATCHES-RESOURCE-OF-MY-FRIENDS: entering procedure: count turtle-group-and-me " count turtle-group-and-me ": " turtle-group-and-me)
  ;; max-prl : maximum amount of of resource ever seen on the patches of myself and all my friends (=turtle-group), prl = Patch Resource Level
  ;; prl-ticker : a ticker that increments by 1 each tick under the conditions described below
  ;  PRL-TICKER-START - THE TICKER starts ticking when total friends patch resource level drops below PRL-TICKER-START% of the maximum recorded PRL
  ;; PRL-TICKER-STOP - THE TICKER stops ticking when total friends patch resource level raise above PRL-TICKER-STOP% of the maximum recorded PRL
  ;; PRL-TICKER-MAX - when the ticker has been active for PRL-TICKER-MAX ticks, the alert is raised and turtle-group is asked to lower harvest
  ;; current-prl : calculated total amount of resources currently available on the patches where all the group is

  let _current-prl 0
  ask turtle-group-and-me [
    set _current-prl _current-prl + [ patch-resource ] of patch-here
  ]
  if _current-prl > max-prl[
    set max-prl _current-prl
  ]
  ifelse prl-ticker = 0 [
    debugging "adaptive" (list "MEMORIZE-PATCHES-RESOURCE-OF-MY-FRIENDS: ticker null current prl " _current-prl "-start level:" (PRL-TICKER-START * max-prl))
    if _current-prl <= ( PRL-TICKER-START * max-prl) [
      set prl-ticker prl-ticker + 1
    ]
  ][
    debugging "adaptive" (list "MEMORIZE-PATCHES-RESOURCE-OF-MY-FRIENDS: ticker NOT null current prl " _current-prl "-stop level:" (PRL-TICKER-STOP * max-prl))
    ifelse _current-prl > (PRL-TICKER-STOP * max-prl) [
      set prl-ticker 0
    ][
      set prl-ticker prl-ticker + 1
    ]
  ]
  if prl-ticker = PRL-TICKER-MAX [
    debugging "adaptive" (list "ALERT:")
    debugging "adaptive" (list "MEMORIZE-PATCHES-RESOURCE-OF-MY-FRIENDS: requesting " count turtle-group-and-me " of my friends to harvest a bit LESS " )
    harvest-a-bit  "less" turtle-group-and-me DECREASE-PCT                ;; Turtle is asking her turtle group to harvest more but also herself.
  ]
  ;; the reset of prl-ticker is done at the end of the to go procedure in "reset-alert"
end

to memorize-hungry-friends-count
  ifelse hfc-ticker = 0 [
    if hungry-friends-count > ( HFC-TICKER-START * count turtle-group )[
      set hfc-ticker hfc-ticker + 1
    ]
  ][
    ifelse hungry-friends-count <= ( HFC-TICKER-STOP * count turtle-group ) [
      set hfc-ticker 0
    ][
      set hfc-ticker hfc-ticker + 1
    ]
  ]
  if hfc-ticker = HFC-TICKER-MAX [
    debugging "adaptive" (list "ALERT:")
    debugging "adaptive" (list "MEMORIZE-HUNGRY-FRIENDS-COUNT: requesting " count turtle-group-and-me " of my friends to harvest a bit more " )
    harvest-a-bit  "more" turtle-group-and-me INCREASE-PCT                ;; Turtle is asking her turtle group to harvest more but also herself.
  ]
  ;; the reset of hfc-ticker is done at the end of the to go procedure
end

to-report decide [ list-probabilities list-actions ]

  let _decide first rnd:weighted-one-of-list (map list list-actions list-probabilities) last
  debugging "subproc" (list "DECIDE:probabilities=" list-probabilities "-list_actions=" list-actions "-decision=" _decide)
  report _decide

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       N  E  T  W  O  R  K  I  N  G
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-network
  ;; select network type from the chooser
  clear-links ;; clear links
  if network-type = "no-network" [no-network]
  if network-type = "random_simple" [random_wire1]
  if network-type = "random_num_nodes" [random_wire2]
  ;; if network-type = "random_max_links" [random_wire3]
  if network-type = "random_prob" [random_wire4] ;; requires to set prob > 0 to work
  if network-type = "one-community" [one-community]
  if network-type = "preferential-attachment" [preferential-attachment]
  ask links [
    ifelse show-link?  [ show-link ] [ hide-link ]
    set strength (1 + random-normal (MAX-LINK-STRENGTH / 2) 1)
    ;; set label strength ;; if you don't want to see the strength value on every link please comment this line
    set label-color white
  ]
end

to no-network
  crt nb-villagers [
    setup-each-turtle
  ]
end


to random_wire4
  ask links [die]
  nw:generate-random turtles links nb-villagers wiring-probability [ setup-each-turtle  ]
end

to one-community
  ;; it works as one community
  nw:generate-star turtles links nb-villagers [ setup-each-turtle ]
end

to preferential-attachment
  ;; if nb-villagers = 1 [no-network] ;; If there is 1 or less humans act like no-network
  ifelse nb-villagers <= min-degree or nb-villagers = 1 [
    user-message "nb-villagers too small for this network - no network will be created"
    no-network
  ][

    if nb-villagers >= 2 [nw:generate-preferential-attachment turtles links nb-villagers min-degree [ setup-each-turtle ]]
    debugging-obs (list "PREFERENTIAL-ATTACHMENT:nb-villagers:" nb-villagers "-min-degree:" min-degree )
  ]
end





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     G L O B A L    R  E  P  O  R  T  E  R  S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report total-resource-reporter
  set total-resource sum [ patch-resource ] of patches
  report total-resource
end

to-report total-turtle-resource-reporter
    let _total-turtle-resource sum [ turtle-resource ] of turtles
  report _total-turtle-resource
end

to-report number-of-hungry-turtles
  report count turtles with [ hungry? = true ]
end

to-report total-quantity-harvested
  report sum [ current-actual-quantity-harvested  ] of turtles
end

to-report total-patch-regrowth
  report sum [ patch-regrowth  ] of patches
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     P R O C E D U R E S    N O T    U S E D    F O R    N O W
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report decide-harvest-max [ a-patch ]  ;; turtle proc

  let _quantity-harvested list min turtle-harvest [ patch-resource ] of a-patch

  report _quantity-harvested
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C E N T R A L I T Y    M E A S U R E S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report max-links ;; Report the maximum number of links that can be added to a random network.
  ;; given an specific number of nodes, with an arbitrary upper bound of 500
  report min (list (nb-villagers * (nb-villagers - 1) / 2) 500)
end

to betweenness ;; is the sum of the proportion of shortest paths passing through the current turtle
  ;; for every other possible pair of turtles
  centrality [ -> nw:betweenness-centrality ]
end

to eigenvector ;; amount of influence a node has on a network (normalized).
  centrality [ -> nw:eigenvector-centrality ]
end

to closeness ;; for every turtle: is the inverse of the average of it's distances
  ;; to all other turtles.
  centrality [ -> nw:closeness-centrality ]
end

; Takes a centrality measure as a reporter task, runs it for all nodes
; and set labels, sizes and colors of turtles to illustrate result
to centrality [ measure ]
  nw:set-context turtles links
  ask turtles [
    let _result (runresult measure) ; run the task for the turtle
    ifelse is-number? _result [
      set label precision _result 2
      set size _result
    ]
    [
      set label _result
      set size 1
    ]
  ]
  normalize-sizes-and-colors
end

;; DETECT AND COLOUR CLUSTERS
to community-detection
  nw:set-context turtles links
  color-clusters nw:louvain-communities ;; detects community structure present in the network maximizing modularity using Louvain method
end

to normalize-sizes-and-colors
  if count turtles > 0 [
    let _sizes sort [ size ] of turtles ; initial sizes in increasing order
    let _delta last _sizes - first _sizes ; difference between biggest and smallest
    ifelse _delta = 0 [ ; if they are all the same size
      ask turtles [ set size 1 ]
    ]
    [ ; remap the size to a range between 0.5 and 2.5
      ask turtles [ set size ((size - first _sizes) / _delta) * 2 + 0.5 ]
    ]
    ask turtles [ set color scale-color red size 0 5 ] ; using a higher range max not to get too white
  ]
end


to color-clusters [ _clusters ]
  ;; reset the colors
  ask turtles [ set color gray ]
  ask links [ set color gray - 2 ]
  let _number length _clusters
  ;; it generates unique colour for each cluster
  let _shades n-values _number [ _index -> (360 * _index / _number) ]

  ;; loop through the clusters and colors
  (foreach _clusters _shades [ [_cluster _shade] ->
    ask _cluster [ ; for each node in the cluster
  ;; color the turtle with cluster color
      set color hsb _shade 100 100
  ;; color cluster links a little darker than the cluster color
      ask my-links with [ member? other-end _cluster ] [ set color hsb _shade 100 75 ]
    ]
  ])
end


;; Not very useful Network. I am not calling this. If you want to try, you can create a button an call this procedure from the interface.
to random_wire1     ;; Random network. Ask each villager to create a link with another random villager.
  ;; If a villager tries to connect with other villager which is already linked, no new link appears.
  ;; Everyone is connected here (everone who is a villager).
  no-network
  ask turtles [
    create-link-with one-of other turtles
  ]
end

;; Not very useful Network. I am not calling this. If you want to try, you can create a button an call this procedure from the interface.
to random_wire2  ;; Random network. Ask a random villager to create a link with another random villager.
  ;; If a villager tries to connect with other villager which is already linked, no new link appears.
  ;; Not everyone is connected here (It depends on the nb-villagers selected on the slider).
  repeat nb-villagers [
   ask one-of turtles [
      create-link-with one-of other turtles
    ]
  ]

end
;; Not very useful Network. I am not calling this. If you want to try, you can create a button an call this procedure from the interface.
;;to random_wire3 ;; Erdős-Rényi random network.
  ;; This type of random network ensures a number of links.
;;   if number-of-links > max-links [ set number-of-links max-links ]
;;   while [count links < number-of-links ] [
;;     ask one-of turtles [
;;       create-link-with one-of other turtles
;;     ]
;;   ]
;; end

to-report get-patch-variation [ a-patch ]
  let _linked-turtles turtle-group
  let _current-value [ patch-resource ] of a-patch
  let _group-max 0
  let _group-min MAX-ON-BEST-PATCH
  let _total-variation 0
  let _percent-variation 0
  let _decrease? true
  let _depleted-maybe? true

  let _max _current-value
  let _min _current-value

  ask _linked-turtles [
    if table:has-key? turtle-memory [ patch-id ] of a-patch
    [
      let _list-of-resource table:get turtle-memory [ patch-id ] of a-patch

      set _max max ( _list-of-resource )
      set _min min ( _list-of-resource )
      set _group-max max list _group-max _max
      set _group-min min list _group-min _min
      ;; debugging (list "PATCH-VARIATION: _max:" _max "-_min:" _min "-_group-max:" _group-max "-_group-min:" _group-min )
    ]
  ]

  ;; variation will be calculated by comparing historic values with current value

  if _current-value > _group-max [
    ;; if the patch is full to the max ever known to these turtles
    ;; it is assumed not to be depleted
    set _decrease? false
    set _depleted-maybe? false
  ]
  if _current-value <= _group-max and _current-value > _group-min [
    set _decrease? true
    set _depleted-maybe? false
  ]
  if  _current-value <= _group-min [
    ; if the patch is at the worst it's ever been seen it's assumed to be depleted
    set _decrease? true
    set _depleted-maybe? true
  ]
  set _total-variation _current-value - _group-max
  ifelse _group-max != 0 [
    set _percent-variation _total-variation / _group-max
  ][
    ;; debugging (list "PATCH-VARIATION: patch has gone to zero yet it has regrown" )
  ]

  ;; debugging (list "PATCH-VARIATION: _decrease?:" _decrease? "_depleted-maybe?:" _depleted-maybe? "-_percent-variation:" _percent-variation "-_total-variation:" _total-variation )
  report (list _decrease? _depleted-maybe? _percent-variation _total-variation _group-max _group-min )
end

to set-turtle-group-with-levels [ link-distance ] ;; turtle-proc
  ifelse  link-distance > 0 [
    let all-neighbors other nw:turtles-in-radius link-distance
    set turtle-group (list) ; initialize to empty list
    foreach range link-distance [ i ->
      let neighbors-at-this-level all-neighbors with [
        nw:distance-to myself = i + 1
      ]
      set turtle-group lput neighbors-at-this-level turtle-group
    ]
  ][
    set turtle-group no-turtles
  ]

  ; demonstrate how to access the levels (sorted only for display purposes)
  ;;ask one-of turtles [
  ;;  show sort item 0 turtle-group ; first level neighbors
  ;;  show sort item 1 turtle-group ; second level neighbors
  ;;  show sort item 2 turtle-group ; third level neighbors
  ;; ]

end

;; NOT USED - ONLY FOR TEST - WILL CLEAN-UP LATER
to setup-patches-test
  ;; used to test the counters etc...
    ask patches [
     set patch-resource 1  ;; round resource levels to whole numbers
     set patch-max-resource 0      ;; initial resource level is also maximum
     set-patch-color
  ]
end

;; NOT USED ???
to memorize-current-patch-resource-level

  let _list-of-resource-level []

  ifelse table:has-key? turtle-memory [ patch-id ] of patch-here [
    set _list-of-resource-level table:get turtle-memory [ patch-id ] of patch-here
    let _length length _list-of-resource-level
    ;; debugging (list "MEMORIZE-CURRENT-PATCH, turtles remembers patch " [ patch-id ] of patch-here " list:"  _list-of-resource-level "- length: " _length)
    if _length = turtle-memory-size [
      ;; drop last item before adding a new one to keep the length
      set _list-of-resource-level but-last _list-of-resource-level
    ]
    ;; the most recent memory goes at the beginning of the list
    set _list-of-resource-level insert-item 0 _list-of-resource-level [ patch-resource ] of patch-here
    ;; debugging (list "MEMORIZE-CURRENT-PATCH, turtles remembers patch, new list "   _list-of-resource-level )
  ][
    set _list-of-resource-level (list [ patch-resource ] of patch-here)
    ;; debugging (list "MEMORIZE-CURRENT-PATCH, turtles does not remember patch " [ patch-id ] of patch-here " list:"  _list-of-resource-level )
  ]

  table:put turtle-memory [ patch-id ] of patch-here  _list-of-resource-level
  ;; debugging (list "MEMORIZE-CURRENT-PATCH, new table entry " table:get turtle-memory [ patch-id ] of patch-here)
end


;;; NOT USED --->
to-report decide-harvest-2 [ a-patch ]  ;; turtle proc
  ;; turtle will check state of the patch based on her memory and the memory of her linked neighbors
  ;; get-patch-variation returns a list of values
  ;; (list 0: _decrease? 1: _depleted-maybe? 2:_percent-variation 3:_total-variation _4:group-max 5:_group-min )
  ;; position in list begins at 0

  let _get-patch-variation get-patch-variation patch-here
  let _depleted-maybe? position 1 _get-patch-variation
  let _decrease? position 1 _get-patch-variation

  ;; Strategie 1 : Doesn't care about anything and consume the max it can
  let _decide-harvest-1 turtle-harvest
  ;; Strategie 2 : Consume the max it can except when history indicates that the patch is depleted
  let _decide-harvest-2 turtle-harvest
  if  _decrease? = true [
    set _decide-harvest-2 0
  ]
  ;; Strategie 3 : Also is more precautionous is there has been a decrease

  let _possible-harvest (list _decide-harvest-1 _decide-harvest-2 )
  let _probs (list  0.2 0.8 )

  let _decision decide _probs _possible-harvest

 ;; debugging (list "DECIDE-HARVEST:on patch " a-patch " _decision " _decision "_possible-harvest:" _possible-harvest )
  report _decision
end
;;; <--- NOT USED
@#$#@#$#@
GRAPHICS-WINDOW
207
10
644
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
107
22
170
55
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
65
194
98
nb-villagers
nb-villagers
1
500
141.0
10
1
NIL
HORIZONTAL

MONITOR
704
461
893
506
NIL
total-resource
17
1
11

PLOT
207
605
697
778
Total resources
Time
Total resources
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Land Rsc" 1.0 0 -16777216 true "" "plot total-resource-reporter"
"Turtles Rsc" 1.0 0 -15575016 true "" "plot total-turtle-resource-reporter"
"Harvested Rsc" 1.0 0 -14454117 true "" "plot total-quantity-harvested"

OUTPUT
648
10
1658
456
12

SWITCH
1553
463
1659
496
DEBUG
DEBUG
1
1
-1000

SLIDER
1421
464
1547
497
DEBUG-RATE
DEBUG-RATE
0.01
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
15
582
198
615
wiring-probability
wiring-probability
0
0.2
0.16599
0.00001
1
NIL
HORIZONTAL

MONITOR
13
508
71
553
max-deg
max [count link-neighbors] of turtles
1
1
11

MONITOR
73
508
130
553
min-deg
min [count link-neighbors] of turtles
1
1
11

MONITOR
134
509
191
554
nb links
count links
1
1
11

CHOOSER
13
454
194
499
network-type
network-type
"no-network" "random_prob" "one-community" "preferential-attachment"
3

SLIDER
15
634
130
667
min-degree
min-degree
0
10
2.0
1
1
NIL
HORIZONTAL

PLOT
206
451
697
601
Hungry turtles
#HungryTurtles
Time
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot number-of-hungry-turtles"

SWITCH
1423
538
1660
571
debugging-agentset?
debugging-agentset?
1
1
-1000

SLIDER
1422
499
1659
532
debugging-agentset-nb
debugging-agentset-nb
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
8
220
201
253
INIT-HARVEST-LEVEL
INIT-HARVEST-LEVEL
0
1
1.0
0.05
1
NIL
HORIZONTAL

SLIDER
8
257
202
290
LINK-TRANSMISSION-DISTANCE
LINK-TRANSMISSION-DISTANCE
0
5
1.0
1
1
NIL
HORIZONTAL

BUTTON
9
297
78
330
Hubs
highlight-hubs turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
9
102
194
135
adaptive-harvest?
adaptive-harvest?
0
1
-1000

BUTTON
85
297
159
330
1 Hub
highlight-hubs turtle-set one-of turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1287
619
1660
769
Values per turtle
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"# Hungry friends" 1.0 1 -16777216 true "" "histogram [ hungry-friends-count ] of turtles"
"Qty harvested" 1.0 1 -15302303 true "" "histogram [ current-actual-quantity-harvested  ] of turtles"

PLOT
904
619
1281
769
Resources
NIL
NIL
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"rsc exchanged" 1.0 0 -16777216 true "" "plot total-food-exchanged"

CHOOSER
15
676
167
721
regrowth-chooser
regrowth-chooser
"with-depletion" "always-regrow"
1

PLOT
902
462
1282
612
Qty Harvested vs Quantity Regrown
NIL
NIL
200.0
10.0
0.0
10.0
true
true
"" "if  ticks < 5 [ clear-plot ]"
PENS
"Harvested" 1.0 0 -5298144 true "" "plot total-quantity-harvested"
" Regrown" 1.0 0 -15637942 true "" "plot total-patch-regrowth"

CHOOSER
704
695
892
740
color-chooser
color-chooser
"turtle-backpack" "turtle-resource-ticker" "turtle-hunger-ticker" "turtle-connectivity"
0

TEXTBOX
17
567
167
585
For random network:
12
0.0
1

TEXTBOX
16
617
192
647
For preferential network:
12
0.0
1

SLIDER
9
160
199
193
MIN-RSC-SAVING-PCT
MIN-RSC-SAVING-PCT
0
3
3.0
0.05
1
NIL
HORIZONTAL

TEXTBOX
17
139
239
169
When adaptive harvest is off:
12
0.0
1

TEXTBOX
12
201
252
231
When adaptive harvest is on:
12
0.0
1

BUTTON
820
743
892
776
Reset size
reset-size
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
707
628
857
646
Visuals
12
0.0
1

BUTTON
702
744
757
777
Color
set-color
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
704
646
842
679
show-link?
show-link?
0
1
-1000

BUTTON
19
367
171
400
Reset Simulation
reset-simulation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
21
93
54
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

There’s a maximum rate of exploitation of common-pool resources (CPR) beyond which the resources don’t have time to replenish and are slowly depleted.

We propose to model the interactions of a group of humans with a natural CPR, making the hypothesis that what makes the difference between a sustainable outcome or a tragedy is the nature of the social network between the

## HOW IT WORKS

The humans belong to a specific initial social network, living off the resource, harvesting and sharing it through their social network, and reviewing their strategy for resource harvesting depending on information they collect and share about the state of the resources they access. We are going to compare the outcome of the simulation with different network topology and bond strength, to the case with no network, on the total quantity of resources over time.

This model starts with initializing global variables (MAX-ON-BEST-PATCH, MAX-HUMAN-VISION, MIN-HUMAN-HUNGER and MAX-HUMAN-HARVEST), setting resource-patches (

  setup-patches
  setup-turtles ;; setup humans
  setup-network

At each step villagers move (depending on their strategy), harvest and consume resources, learn or memorize information about the resources and share it with their nearby nodes, and take a decision about keep their strategy or change it.

## HOW TO USE IT

;; I think we can fix - Set the percentage-of-best-land from the slider.
### INITIAL SETUP

(1) Set the number of villagers from the slider.

(2) (2.1)Set "Adapative harvest" switch to False to find a sustainable set of parameters. Non Adaptive harvest, or sustainable harvest will let each turtle only consume its hunger, no more no less. If the parameters cannot be sustainable like that, then that means it's not possible to feed all those turtles with the current landscape of resources.
    (2.2) Set "Adaptive harvest" to True when you want turtles to start adapting their harvest based on the messages they send to each other through their particular network configuration.
          In that case, you can also choose the "Initial Harvest Level". If the Initial Harvest level is set to zero, then the turtle will only consume the minimum allowed. Experiments can set this minimum allowed to the turtle-hunger or else to zero. By default it is set to the turtle hunger.
If greater than zero the "Initial harvest level" indicates what is the percentage between min possible harvest and max possible harvest that the turtle should consume (as recommended). 
During the simulation, turtles receiving too much distress signals (or the contrary) will send messages to raise or lower that "Harvest Level". The messages are only sent to the turtles linked to the originator of the message by as many as LINK-TRANSMISSION-DISTANCE links.

(3) Define network properties

(4) Run Setup
Press Setup.

### SETUP WITHOUT CHANGING NETWORK LINKS AND STRENGTH

### HIGHLIGHT COMMUNICATION HUBS

(1) choose the link transmission distance LINK-TRANSMISSION-DISTANCE. This indicates how many links a message can travel from its originator. 
(2) click Hub
All turtles will send 1 message to all their neighbors that are connected to them by max LINK-TRANSMISSION-DISTANCE. The count of messages received by each turtle is going to measure their "hub-iness" . The turtles are going to be colored to higlight the hubs in bright pink
(3) if you wish to reset colors, click the button "Reset Hub"

### RUN THE SIMULATION
Press Go.

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS



NETWORKS:

Wilensky, U., Rand, W. (2008). NetLogo Random Network model. http://ccl.northwestern.edu/netlogo/models/RandomNetwork. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Wilensky, U., Rand, W. (2008). NetLogo NW General Examples model.

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)

Wilensky, U. (2005). NetLogo GasLab Circular Particles model. http://ccl.northwestern.edu/netlogo/models/GasLabCircularParticles. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## ASSUMPTIONS

For simplifying the model we assume that the population (villagers) is constant (nobody is born or dies, nobody is moving to another place to live). Also, we assume that every villagers on the screen lives from the harvest (maybe he/she and his/her family) but we are representating just the head of household who actually do the harvest for support his family group.

RESOURCES-PATCHES
We assume that the resources had the faculty to grow in a rate of 0.1% (every tick) if they are in at least an amount of 0.5%. Resources have a decay rate of 0.2%, this represents that the resource suffer "depreciation" or aging in this case, as a natural forest.


## COMMENTS

The extreme scenarios of percent-best-land are very predictable.
We need to focus on a reasonable range in which both depletion and sustainability are possible outcomes. I obeserved that the percent-best-land range between 12 and 18% is where things are happening. We can try a broad range like 10-25%. (this is for discussing, maybe it is not important now, and the range could change when we add the network, but it will be importante for the simulations in the final report).
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
