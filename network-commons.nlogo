;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     G  U  I  D  E  L  I  N  E  S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  globals in uppercase = constants e.g. MAX-ON-BEST-PATCH
;;  variables in a procedures that start with _ ==> local variables only used in that procedure
;;  variables booleans ==> named with a ? at the end e.g. depleted?
;;  all % are between 0 and 1
;;
;;  local variables ==> _local
;; Useful doco:
;; on selecting an action based on a probability : https://stackoverflow.com/questions/41901313/netlogo-assign-variable-using-probabilities/41902311#41902311
;; on coding to detect overlapping of turtles : GasLab Circular Particles model by Wilensky on netlogo model library


extensions [ rnd table palette nw]
;;breed [villagers villager] ;; http://ccl.northwestern.edu/netlogo/docs/dict/breed.html
;; directed-link-breed [ friendships friendship ] ;; between villagers

globals
[
  ;; all these variables get their values in "initialize-globals".
  ;; values won't change over time
  ;; these values are used in the setup procedures

  ;; (slider) PERCENT-BEST-LAND   ; percentage of best land when setting up the patches (density of resource)
  MAX-ON-BEST-PATCH   ; maximum value of resource the best patch can hold
  PATCH-MIN-TO-REGROW ; need to leave at least % amount of the max-patch resource for this patch to regrow
  PATCH-REGROWTH-RATE ; % of max resource on patch that regrows every tick if over the min-to-regrow
  PATCH-DECAY-RATE    ;
  MAX-TURTLE-SIZE     ; used for visuals

  MIN-TURTLE-DISTANCE ; minimum patches a turtle has to stay away from others
  FIND-NEW-PLACE-PCT  ; percentage of neighboring turtles hungry that will make a turtle go to look for a new place
  MWF-TICKER-MAX      ; for how many ticks a turtle is going to follow her friend
  FNP-TICKER-MAX      ; for how many ticks a turtle is going to walk in the direction of a new place

  ;; (slider) MAX-TURTLE-VISION   ; how many patches ahead a turtle can see
  MIN-TURTLE-HUNGER   ; how many units of resource a turtle needs to consume each tick
  HGR-TICKER-MAX      ; level of hunger that causes the turtle to die
  MAX-TURTLE-HARVEST  ; maximum that a human can harvest during a tick
  ;; (slider) MAX-TURTLE-BACKPACK ; maximum turtle can carry in her backpack (amount of resource max in backpack)
  MIN-TURTLE-HARVEST  ; minimum amount that a turtle is trying to consume each step
  ;; (slider) FACTOR-DIV          ; weight of the amount of resource on the patch when the turtle, the bigger the less weight
                      ; e.g. if FACTOR DIV = 4  the amount of resource on the patch needs to be at least 4 times higher than the amount a turle can harvest to not have an influence on the amount harvested
  MAX-TURTLE-MEMORY   ; how many items a turtle can remember in a list ;;NOT USED?

  MAX-LINK-STRENGTH   ; maximum strength of the link between 2 turtles

  ;; (slider) HFC-TICKER-START    ; %pct of friends hungry that kcik off the hungry friend count "distress ticker"
  ;; (slider) HFC-TICKER-STOP     ; %pct of friends hungry that stop the ticker
  ;; (slider) HFC-TICKER-MAX      ; max before an alert is raised


  ;; (slider) PRL-TICKER-START    ;- THE TICKER starts ticking when total friends patch resource level drops below PRL-TICKER-START% of the maximum recorded PRL
  ;; (slider) PRL-TICKER-STOP     ;- THE TICKER stops ticking when total friends patch resource level raise above PRL-TICKER-STOP% of the maximum recorded PRL
  ;; (slider) PRL-TICKER-MAX      ;- when the ticker has been active for PRL-TICKER-MAX ticks, the alert is raised and turtle-group is asked to lower harvest
  PRL-RESULT-TICKER-MAX           ; number of tick the turtle needs to wait to check the result of her command

  ;; (slider) INCREASE-PCT        ; pct increase when asked to harvest a bit more
  ;; (slider) DECREASE-PCT        ; pct decrease when asked to harvest a bit less

  ;; (NOW A SLIDER) LINK-TRANSMISSION-DISTANCE ;  indicates how far away on the network information spreads, a value of zero means there's no communication
  ;; (NOW A SLIDER) DEBUG-RATE         ; proportion of agents for which the debugging is activeOW

  ;; these variables evolve with the simulation

  total-resource     ; total resource available summed over all the resource patches
  total-food-exchanged ; amount of resource given to hungry turtles
  debugging-agentset    ;  turtles that are followed by the debugging procedure when "follow agent-set switch" is true on interface
  random-run-number

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
  turtle-group             ; group of linked turtle by a link radius = LINK-TRANSMISSION-DISTANCE

  ;; TURTLE CURRENT PROPERTIES
  ;===========================
  ;; turtles characteristics that change over time

  ;; RELATED TO HARVEST
  turtle-resource                 ; the amount of resource that the turtle privately owns after harvesting (each harvest adds to it up to a max). Can be eaten.
  turtle-wealth                   ; the amount of resource converted to wealth, i.e. when the backpack is full the excess is moved to wealth. Wealth cannot be eaten.
  turtle-current-harvest          ; amount that the turtle has decided to harvest
  current-actual-quantity-harvested ; quantity that the turtle has actually harvested this tick
  current-harvest-recommended-level  ; considering the min that the turtle is willing to harvest and the max that a turtle can harvest
                                     ; recommended harvest amount = min + (max - min) * current-harvest-recommended-level

  ;; MESSAGING & CONNECTIVITY
  ;;=========================
  turtle-test-hub                 ; count of how many messages that turtle has received when testing for hubs
  community                       ; turtle louvain community as detected by nw:louvain-community

  ;; MOVE
  ;;=====

  new-place                   ; new place (= patch) the turtle is heading towards
  move-friend                 ; friend the turtle is moving with
  move-with-friend-ticker     ; counter of ticks the turtle has been moving with her friend
  find-new-place-ticker       ; counter of ticks the turtle has been heading toward her new place

  ;; MEMORY AND STRATEGY, ALERTING LEVELS
  ;;=====================================
  turtle-hunger-level          ; each tick the turtle is hungry consecutively it adds 1, each tick the turtle is not hungry it removes 1 (with a min of zero)
  dead?                        ; turtle is dead

  hungry?                      ; set to true when a turtle cannot consume "turtle-hunger" amount of resource in one tick
  hungry-friends-count         ; amount of friends that have told they are hungry
  hfc-ticker                   ; start counting every tick hungry-friends-count is above a certain treshold HFC-TICKER-START
                               ; stop counting when number of hungry friends HFC-TICKER-STOP
                               ; alert people when ticker reached HFC-TICKER-MAX to consume more
  prl-ticker                   ; a ticker that increments by 1 each tick when total resources found on all friends patches (turtle-group-and-me) trigger alert levels
  prl-result-ticker            ; a ticker that counts the number of ticks until the turtle checks if her command to harvest less have worked
  prl-result-current-situation ; current level of resources on the turtle group patches when the turtle request to harvest less
  current-prl                  ; calculated total amount of resources currently available on the patches where all the group (turtle-group-and-me) is
  max-prl                      ; maximum amount of of resource ever seen on the patches of myself and all my friends (=turtle-group-and-me), prl = Patch Resource Level:

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
  ;;===========
    turtle-memory                   ; turtle's memory  ;; NOT USED
    turtle-memory-size       ; size of a turtle's memory (;; NOT USED)
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
      if  proc-name = "message" [;; or proc-name-chooser = "all" or proc-name = "subproc" [
        ;;if random-float 1 < DEBUG-RATE [
          output-type but-last list-values
          output-show last list-values
        ;;]
      ]
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

  set random-run-number random 100000000

  ;; turtles intrisic properties

  ;; NOW A SLIDER set MAX-TURTLE-VISION 8
  set MIN-TURTLE-HUNGER 2
  set MAX-TURTLE-HARVEST 5
  set MIN-TURTLE-HARVEST 2
  set MAX-TURTLE-MEMORY 5
  ;; NOW A SLIDER set MAX-TURTLE-BACKPACK 4    ;; The turtle can carry the amount of 10 times her max harvest in her backpack, the rest goes in turtle-wealth
  set HGR-TICKER-MAX 100       ;; turtles dies if her turtle-hunger-level reaches 100

  ;; patches

  ;; NOW A SLIDER set PERCENT-BEST-LAND 0.06
  set MAX-ON-BEST-PATCH 100
  set PATCH-MIN-TO-REGROW 0.5   ;; need to leave at least % amount of the max-patch resource for this patch to regrow
  set PATCH-REGROWTH-RATE 0.15  ;; % of max resource on patch that regrows every tick if over the min-to-regrow
  set PATCH-DECAY-RATE 0.2

  ;; harvest

  ;; NOW A SLIDER set FACTOR-DIV 4

  ;; movement

  set MIN-TURTLE-DISTANCE 2    ;; one turtle per patch
  set FIND-NEW-PLACE-PCT 0.5   ;; treshold for the amount fo hungry turtles that trigger a move
  set MWF-TICKER-MAX 20        ;; turtle tries to reach friend for max 50 ticks
  set FNP-TICKER-MAX 20        ;; turtle tries to reach new place for max 50 ticks

  ;; communication

  set MAX-LINK-STRENGTH 10     ;;
  ;; NOW A SLIDER set LINK-TRANSMISSION-DISTANCE 1 ;; indicates how far away on the network information spreads, a value of zero means there's no communication

  ;; adaptive behavior

  ;; NOW A SLIDER set HFC-TICKER-START 0.5
  ;; NOW A SLIDER set HFC-TICKER-STOP 0.3
  ;; NOW A SLIDER set HFC-TICKER-MAX 10
  ;; NOW A SLIDER set PRL-TICKER-START 0.5
  ;; NOW A SLIDER set PRL-TICKER-STOP 0.7
  ;; NOW A SLIDER set PRL-TICKER-MAX 10
  set PRL-RESULT-TICKER-MAX 3
  ;; NOW A SLIDER set INCREASE-PCT 0.1
  ;; NOW A SLIDER set DECREASE-PCT 0.1

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

to setup2
  clear-all
  initialize-globals
  setup-patches
  set-default-shape turtles "person"
  load-network                  ;; load gml file
  setup-links                   ;; setup the link strength if there's none
  nw:set-context turtles links  ;; set up network extension context
  setup-turtles
  set-turtle-test-hub           ;; needs to happen after setup-turtles
  initialize-debugging
  save-setup
  reset-ticks
end

to load-network
  let _nw-filename (word "./networks/" nw-filename-chooser)
  nw:load-gml _nw-filename turtles links [ setup-each-turtle ]
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
   set label who
   set label-color black
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
  ask turtles-alive  [
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
  set turtle-wealth 0
  set hfc-ticker 0
  set prl-ticker 0
  set prl-result-ticker 0
  set move-with-friend-ticker 0
  set find-new-place-ticker 0
  set max-prl 0
  set turtle-resource 0
  set current-actual-quantity-harvested 0
  set hungry? false
  set dead? false
  set has-moved? false
  set hidden? false
  set-turtle-memory
  set label who
end

to die-if-too-hungry   ;; turtle proc
  if turtles-die? = true [
    if turtle-hunger-level >= HGR-TICKER-MAX [
      ;; set hidden? true
      set shape "x"
      set size 0.5
      set color red
      set label "dead"
      set dead? true
      ask my-links [ die ]
      set turtle-wealth 0
      set hfc-ticker 0
      set prl-ticker 0
      set prl-result-ticker 0
      set move-with-friend-ticker 0
      set find-new-place-ticker 0
      set max-prl 0
      set turtle-resource 0
      set current-actual-quantity-harvested 0
      set hungry? false
      set has-moved? false
      ask turtle-group [ set-turtle-group LINK-TRANSMISSION-DISTANCE ]
      set turtle-group turtle-set nobody
    ]
  ]
end

to set-turtle-memory
  set turtle-memory-size MAX-TURTLE-MEMORY
  set turtle-memory table:make
  memorize-current-patch-resource-level
end

to set-turtle-size-backpack
    ;; change the size of the turtle depending on how much it carries in her backpack
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
    ;; change the size of the turtle depending on how well it is connected
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
  ask turtles with [dead? = false ] [
    set size 1
  ]
end

to set-color
  ask turtles with [dead? = false ] [
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
  if color-chooser = "louvain-community" [
     ;; set-turtle-louvain-community   DOESN'T WORK YET
  ]
  if color-chooser = "turtle-resource-ticker" [
    if prl-ticker = 0 [
      set color brown
      set size 1
      set label who
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
      set label who
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
    set turtle-group other nw:turtles-in-radius link-distance              ;; this will return all the turtles that are LINK-TRANSMISSION-DISTANCE  - self
    set turtle-group turtle-group  with [ dead? = false ]                   ;; removing dead turtles from turtle group
  ][
    set turtle-group no-turtles
  ]
end

to-report turtle-group-and-me ;; turtle proc                                 ;; for cases when you want turtle-group to include self, use "turtle-group-and-me"
  report (turtle-set turtle-group self)
end

to-report turtles-alive ;; obs proc
  report (turtle-set turtles with [ dead? = false ])
end

to-report turtles-alive-here ;; patch proc
  report (turtle-set turtles-here with [ dead? = false ])
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

  ask turtles-alive [
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
    ask turtles with [dead? = false ] [
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

  ask turtles-alive [
    set turtle-test-hub 0
  ]
  ask turtles-alive [
    ask turtle-group [
      set turtle-test-hub turtle-test-hub + 1
    ]
  ]
end

to set-turtle-test-hub

  ;; recalculate turtle-test-hub for all turtles

  ask turtles-alive [
    set turtle-test-hub 0
  ]
  ask turtles-alive [
    ask turtle-group [
      set turtle-test-hub turtle-test-hub + 1
    ]
  ]
end

to set-turtle-louvain-community
  ;; doesn't work with dead turtles
  let _communities nw:louvain-communities
  ;;let _colors sublist  0 (length _communities)  ###
  let _colors palette:scheme-colors "Divergent" "Spectral" length _communities
  ( foreach _communities _colors [ [comm col ] ->
    ask comm [
      set community comm
      set color col
    ]
  ] )
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

  let _filename_1 ""
  let _filename_2 ""
  ifelse experiment-name-chooser = "" [
    set _filename_1 (word "./networks/network-gml-" random-run-number ".txt" )
    ;; set _filename_2 (word "./networks/network-graphml-" random-run-number ".txt" )
  ][
    set _filename_1 (word "./networks/network-gml-" experiment-name-chooser "-" random-run-number ".txt" )
    set _filename_2 (word "./networks/network-graphml-" experiment-name-chooser "-" random-run-number ".txt" )
  ]
  ;; https://networkx.github.io/documentation/networkx-1.9.1/reference/readwrite.gml.html
  nw:save-gml _filename_1
  nw:save-graphml _filename_2
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

  ask turtles-alive [
    set label who
    observe-world    ;; set a few variables like best-visible-turtle, best-visible-patch
    move
    observe-world
    harvest           ;; for each turtle will update the turtle-resource variable based on what they have harvested
    consume
    memorize-and-strategy
    set-turtle-color
    reset-alert
    die-if-too-hungry
  ]

  ask patches [
    regrow
  ]

  if color-chooser = "betweenness-centrality" [
    normalize-sizes-and-colors
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


  let _decision ""

  ;; if already looking for a new place or following a friend, the turtle keep to her decision until the ticker is reached

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

  ;; if not yet followind a friend or reaching for a new place, the turtle needs to decide
  ;; it decided based on what it would harvest between the different locations
  ;; either staying around and harvesting the best neighbouring patch
  ;; or moving to best visible patch

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


  ;; IF TOO MANY HUNGRY    : SCRAP THIS i'M GOING ELSEWHERE AT RANDOM
  ;;  OR TOO MANY TURTLES
  let _turtles_1 turtles-alive in-radius turtle-vision with [ hungry? = true ]
  let _turtles_2 turtles-alive in-radius turtle-vision
  let _max count patches in-radius turtle-vision
  let _new-place one-of patches
  ;; if count _turtles_1 > ( FIND-NEW-PLACE-PCT * _max )[
  if count _turtles_1 >= 4
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


to reposition
  move-to one-of neighbors
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     M  E  S  S  A  G  E  S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to harvest-a-bit [ action some-turtles percentage ]  ;; turtle proc
  debugging "message" (list "HARVEST-A-BIT " action " by pct " percentage " for # " count some-turtles)
  let _turtle-current-harvest-request turtle-current-harvest
  let _requesting-turtle self
  ask some-turtles [
    let _bond-strength get-link-strength-with _requesting-turtle
    let _actual-percentage will-turtle-do-it _bond-strength percentage
    ;; actual-percentage : actual percentage that the turtle is going to harvest min or more
    if  action = "more"  [
        ;; turtle will increase harvesting up to the max they can harvest (turtle-harvest)
        debugging "message" ( list "HARVEST-A-BIT " action ": current harvest request: " _turtle-current-harvest-request)
        set _turtle-current-harvest-request min list (turtle-current-harvest + _actual-percentage * turtle-current-harvest) turtle-harvest
        debugging "message" ( list "HARVEST-A-BIT " action ": amount requested to add:" (_actual-percentage * turtle-current-harvest) "-new harvest request: " _turtle-current-harvest-request)
    ]
    if action = "less"  [
        debugging "message" ( list "HARVEST-A-BIT " action ": current harvest request: " _turtle-current-harvest-request)
        set _turtle-current-harvest-request max list (turtle-current-harvest - _actual-percentage * turtle-current-harvest) 0
        debugging "message" ( list "HARVEST-A-BIT " action ": amount requested to subtract:" (_actual-percentage * turtle-current-harvest) "-new harvest request: " _turtle-current-harvest-request)
    ]
    ;; at the moment we consider that the turtle is going to "obey"
    ;; FUTURE : in the improvments we can get the turtle to do what it's told in proportion to the strength
    ;; of the link between the turtle and the originator of the message
    set turtle-current-harvest _turtle-current-harvest-request
  ]
end

to-report will-turtle-do-it [ bond-strength percentage ]  ;; called by a turtle
  let _actual-percentage 0
  let _prob-do-it 0

  ifelse link-strength-impact-obey? [
    ;; do what you're told more likely when the link is strong
    set _prob-do-it ( bond-strength / MAX-LINK-STRENGTH )
  ][
    set _prob-do-it 1
    ;; always do what you're told
  ]

  let _do? random-float 1
  let p 0
  ifelse _do? <= _prob-do-it
  [
    let _mean 0
    let _bond-strength bond-strength
    if _bond-strength = 0 [ set _bond-strength 0.1 ]
    let _standard-deviation (  ( 1 / 3 ) * ( MAX-LINK-STRENGTH / ( 2 * _bond-strength ) )  )
    set p random-normal _mean _standard-deviation
    if p > 1 [ set p 1 ]
    if p < -1 [ set p -1 ]
    set _actual-percentage ( percentage + ( p * percentage ) )
  ][
    debugging "message" (list "WILL-TURTLE-DO-IT: Nah I won't do it , strength:" bond-strength "-actual-percentage: (should be 0)" _actual-percentage )
  ]

  debugging "message" (list "WILL-TURTLE-DO-IT:  percentage:" percentage "-strength:" bond-strength "-actual-percentage:" _actual-percentage )

  report _actual-percentage
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

  let _quantity-harvested decide-harvest best-neighboring-patch   ;; decide how much the turtle is prepared to harvest on the best-neighboring-patch
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
    ;; debugging-obs (list "HARVEST:best neighboring patch resource was " _patch-resource-old "-now is " patch-resource "-qty harvested=" _actual-quantity-harvested)
  ]

  set turtle-resource turtle-resource + _actual-quantity-harvested
  set current-actual-quantity-harvested _actual-quantity-harvested


  ;; turtle can only carry "MAX-TURTLE-BACKPACK" times the max she can harvest in her backpack
  let _max-backpack (MAX-TURTLE-BACKPACK * turtle-harvest)
  if turtle-resource > _max-backpack [
    set turtle-wealth turtle-wealth + (turtle-resource - _max-backpack)
  ]
  set turtle-resource min list _max-backpack turtle-resource

  debugging "harvest" (list "HARVEST: turtle backpack " turtle-resource "- max backpack:" _max-backpack "-turtle-wealth: " turtle-wealth )

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

  ifelse prl-result-ticker > 0 [
    ;; if turtle has recently sent an alert and should watch what's going on
    ifelse prl-result-ticker = PRL-RESULT-TICKER-MAX [ ;;  if it's time to check the situation
      debugging "message" (list "PRL-CHECKS: time to check the situation again")
      ifelse _current-prl <= prl-result-current-situation [   ;; if there's no improvement
        debugging "message" (list "PRL-CHECKS: damn no better current-prl: " current-prl "-prl-result-current-situation:" prl-result-current-situation )
        harvest-a-bit  "less" turtle-group-and-me DECREASE-PCT                ;; Turtle is asking again to harvest less
        set prl-result-ticker 1 ;; turtle will see if situation improves
      ][
        set prl-result-ticker 0 ;; turtle is happy her actions have worked
      ]
    ][
      set prl-result-ticker prl-result-ticker + 1     ;; too early to say
    ]
  ]
  [
  ;; if turtle doesn't worry yet, should it?
    ifelse prl-ticker = 0 [
      ;; debugging "message" (list "MEMORIZE-PATCHES-RESOURCE-OF-MY-FRIENDS: ticker null current prl " _current-prl "-start level:" (PRL-TICKER-START * max-prl))
      if _current-prl <= ( PRL-TICKER-START * max-prl) [
        set prl-ticker prl-ticker + 1
      ]
    ][
      ;; if the turtle is worrying should it stop?
      ;; debugging "adaptive" (list "MEMORIZE-PATCHES-RESOURCE-OF-MY-FRIENDS: ticker NOT null current prl " _current-prl "-stop level:" (PRL-TICKER-STOP * max-prl))
      ifelse _current-prl > (PRL-TICKER-STOP * max-prl) [
        set prl-ticker 0
      ][
        set prl-ticker prl-ticker + 1
      ]
    ]
    ;; if the turtle has been worrying for too long it raises alert
    if prl-ticker = PRL-TICKER-MAX [
      debugging "message" (list "ALERT:")
      debugging "message" (list "MEMORIZE-PATCHES-RESOURCE-OF-MY-FRIENDS: requesting " count turtle-group-and-me " of my friends to harvest a bit LESS " )
      harvest-a-bit  "less" turtle-group-and-me DECREASE-PCT                ;; Turtle is asking her turtle group to harvest less
      set prl-result-ticker 1 ;; turtle will see if situation improves
      set prl-result-current-situation _current-prl
    ]
  ]
  ;; the reset of prl-ticker is done at the end of the to go procedure in "reset-alert"
end

to memorize-hungry-friends-count
  ifelse hfc-ticker = 0 [
    if hungry-friends-count > ( HFC-TICKER-START * ( count turtle-group-and-me ) )[
      set hfc-ticker hfc-ticker + 1
    ]
  ][
    ifelse hungry-friends-count <= ( HFC-TICKER-STOP * ( count turtle-group-and-me ) ) [
      set hfc-ticker 0
    ][
      set hfc-ticker hfc-ticker + 1
    ]
  ]
  if hfc-ticker = HFC-TICKER-MAX [
    debugging "message" (list "ALERT:")
    debugging "message" (list "MEMORIZE-HUNGRY-FRIENDS-COUNT: requesting " count turtle-group-and-me " of my friends to harvest a bit more " )
    harvest-a-bit  "more" turtle-group-and-me INCREASE-PCT                ;; Turtle is asking her turtle group to harvest more but also herself.
  ]
  ;; the reset of hfc-ticker is done at the end of the to go procedure
end

to-report decide [ list-probabilities list-actions ]

  let _sum 0
  foreach list-probabilities [ [x] ->
    if x  < 0 [ set x 0 ]
    set _sum _sum + x
  ]
  let _decide first rnd:weighted-one-of-list (map list list-actions list-probabilities) last
  debugging "subproc" (list "DECIDE:probabilities=" list-probabilities "-list_actions=" list-actions "-decision=" _decide "-sum prob: " _sum)
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
  ;;ask links [
  ;; ifelse show-link?  [ show-link ] [ hide-link ]
  ;;  set strength (1 + random-normal (MAX-LINK-STRENGTH / 2) 1)
  ;;  ;; set label strength ;; if you don't want to see the strength value on every link please comment this line
  ;;  set label-color white
  ;;]
  setup-links
  nw:set-context turtles links
end

to setup-links
  let _sum 0
  ask links [
    ifelse show-link?  [ show-link ] [ hide-link ]
    set _sum _sum + [ strength ] of self
  ]
  let _id 0
  if _sum = 0 [
    ask links [
      ;; if links strength hasn't been setup
      if strength-chooser = "random" [
        set strength random MAX-LINK-STRENGTH + 1
      ]
      if strength-chooser = "normal" [
        set strength (1 + random-normal (MAX-LINK-STRENGTH / 2) 1)
      ]
      if strength-chooser = "normal-3" [
        set strength (1 + random-normal (MAX-LINK-STRENGTH / 2) 3)
      ]
      if strength-chooser = "all-the-same" [
        set strength link-strength
      ]
      if strength-chooser = "exponential" [
        set strength random-exponential (MAX-LINK-STRENGTH / 2)
      ]
      if strength < 0 [ set strength 0 ]
      if strength > MAX-LINK-STRENGTH [ set strength MAX-LINK-STRENGTH ]
      set label-color white
      set label _id
      set _id _id + 1
    ]
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

;; final commands for Behaviour Space
;; ==================================


to final-command

  let _filename_1 ""
  let _filename_view ""
  let _filename_plots ""
  ifelse experiment-name-chooser = "" [
    set _filename_1 (word "./data/turtles-data-final-command-" random-run-number ".csv" )
    set _filename_view (word "./data/view-final-command-" random-run-number ".png" )
    set _filename_plots (word "./data/plots-final-command-" random-run-number ".csv" )
  ][
    set _filename_1 (word "./data/turtles-data-final-command-" experiment-name-chooser "-" random-run-number ".csv" )
    set _filename_view (word "./data/view-final-command-" experiment-name-chooser "-" random-run-number ".png" )
    set _filename_plots (word "./data/plots-final-command-" experiment-name-chooser "-" random-run-number ".csv" )
  ]
  file-open _filename_1
  file-type (word "link-strength-distribution," link-strength-distribution "\n")
  file-type (word "turtle-centrality-betweenness," turtle-centrality-betweenness "\n")
  file-type (word "turtle-hunger-distribution," turtle-hunger-distribution "\n")
  file-type (word "group-turtle-resource," group-turtle-resource "\n")
  file-type (word "group-turtle-hub," group-turtle-hub "\n")
  file-type (word "group-turtle-wealth," group-turtle-wealth "\n")
  file-type (word "group-turtle-prl," group-turtle-prl "\n")
  file-type (word "group-turtle-hfc," group-turtle-hfc "\n")
  file-type (word "total-wealth," total-wealth "\n")
  file-type (word "total-turtle-resource-reporter," total-turtle-resource-reporter "\n")
  file-type (word "total-resource-reporter," total-resource-reporter "\n")
  file-type (word "number-of-hungry-turtles," number-of-hungry-turtles "\n")
  file-type (word "count turtles," count turtles "\n")
  file-type (word "count links," count links "\n")
  file-close

  export-view _filename_view

  export-all-plots _filename_plots

end

to final-command2
  final-command
  let _filename_interface ""
  ifelse experiment-name-chooser = "" [
    set _filename_interface (word "./data/interface-final-command-" random-run-number ".png" )
  ][
    set _filename_interface (word "./data/interface-final-command-" experiment-name-chooser "-" random-run-number ".png" )
  ]
  export-interface _filename_interface
end

;; Patches reporters
;;==================
to-report total-resource-reporter
  set total-resource sum [ patch-resource ] of patches
  report total-resource
end

to-report total-patch-regrowth
  report sum [ patch-regrowth  ] of patches
end

;; Links reporters
;;==================

to-report link-strength-distribution
  let _list []
  ;;ask turtle-set sort-on [who] links [                                        ;; ask turtles always in the same order
  foreach sort-on [ "label" ] links [ x ->
    ask x [
      set _list lput ( [ strength ] of self ) _list ;; lput add an item at the end of the list (last put)
    ]
  ]
  report _list
end

;; Turtles reporters
;;==================

to-report total-turtle-resource-reporter
    let _total-turtle-resource sum [ turtle-resource ] of turtles
  report _total-turtle-resource
end

to-report total-quantity-harvested
  report sum [ current-actual-quantity-harvested  ] of turtles
end

to-report number-of-hungry-turtles
  report count turtles with [ hungry? = true ]
end

to-report total-wealth
  report sum [ turtle-wealth ] of turtles
end

to-report turtle-centrality-betweenness
  let _list []
                                     ;; ask turtles always in the same order
  foreach sort-on [who] turtles [ x ->
    ask x [

      set _list lput ( betweenness ) _list ;; lput add an item at the end of the list (last put)
    ]
  ]
  report _list
end

to plot-turtle-centrality-betweenness
  clear-plot
  let _list turtle-centrality-betweenness
  foreach _list [[x] -> plot x]
end

to-report turtle-hunger-distribution
  let _list []
  ;;ask turtle-set sort-on [who] turtles [                                        ;; ask turtles always in the same order
  foreach sort-on [who] turtles [ x ->
    ask x [
      set _list lput ( [ turtle-hunger-level ] of self ) _list ;; lput add an item at the end of the list (last put)
    ]
  ]
  report _list
end

to-report group-turtle-resource
  let _list []
  ;;ask turtle-set sort-on [who] turtles [                                        ;; ask turtles always in the same order
  foreach sort-on [who] turtles [ x ->
    ask x [
      set _list lput (sum [ turtle-resource ] of turtle-group-and-me ) _list ;; lput add an item at the end of the list (last put)
    ]
  ]
  report _list
end

to-report group-turtle-hub
  let _list []
  ;;ask turtle-set sort-on [who] turtles [                                        ;; ask turtles always in the same order
  foreach sort-on [who] turtles [ x ->
    ask x [
      set _list lput (count turtle-group ) _list ;; lput add an item at the end of the list (last put)
    ]
  ]
  report _list
end

to plot-group-turtle-resource
  clear-plot
  let _list group-turtle-resource
  foreach _list [[x] -> plot x]
end

to-report group-turtle-wealth
  let _list []
  ;; ask turtle-set sort-on [who] turtles [                                        ;; ask turtles always in the same order
  foreach sort-on [who] turtles [ [x] ->
    ask x [
      set _list lput (sum [ turtle-wealth ] of turtle-group-and-me ) _list ;; lput add an item at the end of the list (last put)
    ]
  ]
  report _list
end

to plot-group-turtle-wealth
  clear-plot
  let _list group-turtle-wealth
  foreach _list [[x] -> plot x]
end

to-report group-turtle-prl   ;; turtle-group current patches resource level (prl)
  let _list []
  foreach sort-on [who] turtles [ [x] ->
    let _current-prl 0
    ask x [
        ask turtle-group-and-me [
        set _current-prl _current-prl + [ patch-resource ] of patch-here
      ]
    ]
    set _list lput _current-prl _list ;; lput add an item at the end of the list (last put)
  ]
  report _list
end

to plot-group-turtle-prl
  clear-plot
  let _list group-turtle-prl
  foreach _list [[x] -> plot x]
end

to-report group-turtle-hfc   ;; turtle-group hungry friends count (hfc)
  let _list []
  foreach sort-on [who] turtles [  [x] ->     ;; ask turtles always in the same order
    ask x [
      set _list lput (count turtle-group-and-me with [ hungry? = true ] ) _list ;; lput add an item at the end of the list (last put)
    ]
  ]
  report _list
end

to plot-group-turtle-hfc
  clear-plot
  let _list group-turtle-hfc
  foreach _list [[x] -> plot x]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     N E T W O R K   M E A S U R E S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to-report betweenness ;; is the sum of the proportion of shortest paths passing through the current turtle
  ;; for every other possible pair of turtles
  report centrality [ -> nw:betweenness-centrality ]
end

to-report eigenvector ;; amount of influence a node has on a network (normalized).
  report centrality [ -> nw:eigenvector-centrality ]
end

to-report closeness ;; for every turtle: is the inverse of the average of it's distances
  ;; to all other turtles.
  report centrality [ -> nw:closeness-centrality ]
end

; Takes a centrality measure as a reporter task, runs it for all nodes
; and set labels, sizes and colors of turtles to illustrate result
to-report centrality [ measure ]            ;; turtle proc
  let _result (runresult measure) ; run the task for the turtle
  report _result
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;     Down from here ---- > P R O C E D U R E S    N O T    U S E D    F O R    N O W
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to normalize-sizes-and-colors
  let _sizes sort [ size ] of turtles ; initial sizes in increasing order
  let _delta last _sizes - first _sizes ; difference between biggest and smallest
  ifelse _delta = 0 [ ; if they are all the same size
    ask turtles [ set size 1 ]
  ][ ; remap the size to a range between 0.5 and 2.5
    ask turtles [ set size ((size - first _sizes) / _delta) * 2 + 0.5 ]
  ]
  ask turtles [ set color scale-color red size 0 5 ] ; using a higher range max not to get too white
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

to-report decide-harvest-max [ a-patch ]  ;; turtle proc

  let _quantity-harvested list min turtle-harvest [ patch-resource ] of a-patch

  report _quantity-harvested
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NOT USED - C E N T R A L I T Y    M E A S U R E S
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report max-links ;; Report the maximum number of links that can be added to a random network.
  ;; given an specific number of nodes, with an arbitrary upper bound of 500
  report min (list (nb-villagers * (nb-villagers - 1) / 2) 500)
end


;; DETECT AND COLOUR CLUSTERS
to community-detection
  nw:set-context turtles links
  color-clusters nw:louvain-communities ;; detects community structure present in the network maximizing modularity using Louvain method
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
97
11
160
44
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
9
117
193
150
nb-villagers
nb-villagers
3
500
79.0
1
1
NIL
HORIZONTAL

MONITOR
902
243
994
288
NIL
total-resource
0
1
11

PLOT
207
605
646
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
903
10
1660
238
12

SWITCH
1664
51
1770
84
DEBUG
DEBUG
1
1
-1000

SLIDER
1665
13
1791
46
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
14
684
197
717
wiring-probability
wiring-probability
0
0.2
0.01056
0.00001
1
NIL
HORIZONTAL

MONITOR
12
610
70
655
max-deg
max [count link-neighbors] of turtles
1
1
11

MONITOR
72
610
129
655
min-deg
min [count link-neighbors] of turtles
1
1
11

MONITOR
133
609
190
654
nb links
count links
1
1
11

CHOOSER
12
556
193
601
network-type
network-type
"no-network" "random_prob" "one-community" "preferential-attachment"
3

SLIDER
14
736
129
769
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
644
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
1664
128
1901
161
debugging-agentset?
debugging-agentset?
1
1
-1000

SLIDER
1663
89
1900
122
debugging-agentset-nb
debugging-agentset-nb
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
7
272
200
305
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
7
309
201
342
LINK-TRANSMISSION-DISTANCE
LINK-TRANSMISSION-DISTANCE
0
5
3.0
1
1
NIL
HORIZONTAL

BUTTON
16
518
85
551
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
8
154
193
187
adaptive-harvest?
adaptive-harvest?
0
1
-1000

BUTTON
116
519
190
552
1 Hub
highlight-hubs turtle-set one-of turtles with [dead? = false ]
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
1188
242
1340
287
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
800.0
1100.0
true
true
"" "if  ticks < 5 [ clear-plot ]"
PENS
"Harvested" 1.0 0 -5298144 true "" "plot total-quantity-harvested"
" Regrown" 1.0 0 -15637942 true "" "plot total-patch-regrowth"

CHOOSER
704
695
921
740
color-chooser
color-chooser
"turtle-backpack" "turtle-resource-ticker" "turtle-hunger-ticker" "turtle-connectivity" "betweenness-centrality"
3

TEXTBOX
16
669
166
687
For random network:
12
0.0
1

TEXTBOX
15
719
191
749
For preferential network:
12
0.0
1

SLIDER
8
212
198
245
MIN-RSC-SAVING-PCT
MIN-RSC-SAVING-PCT
0
3
0.0
0.05
1
NIL
HORIZONTAL

TEXTBOX
16
191
238
221
When adaptive harvest is off:
12
0.0
1

TEXTBOX
11
253
251
283
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
708
668
858
686
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
756
660
894
693
show-link?
show-link?
1
1
-1000

BUTTON
8
46
193
79
Reset - Keep Land and Network
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
9
10
82
43
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

MONITOR
1001
243
1090
288
total-wealth
sum [ turtle-wealth ] of turtles
0
1
11

PLOT
904
304
1279
454
Rsc per Turtle-Group
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "plot-group-turtle-resource"

PLOT
1287
303
1659
453
Hungry friends per turtle group
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -2674135 true "" "plot-group-turtle-hfc"

PLOT
1290
460
1661
610
Wealth per turtle group
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -10263788 true "" "plot-group-turtle-wealth"

CHOOSER
1667
166
1859
211
TURTLE-PROC-CHOOSER
TURTLE-PROC-CHOOSER
"REPORTER" "message"
1

SLIDER
1346
242
1549
275
PERCENT-BEST-LAND
PERCENT-BEST-LAND
0.01
1
0.06
0.01
1
NIL
HORIZONTAL

SLIDER
657
240
875
273
MAX-TURTLE-VISION
MAX-TURTLE-VISION
2
12
8.0
1
1
NIL
HORIZONTAL

SLIDER
657
275
875
308
MAX-TURTLE-BACKPACK
MAX-TURTLE-BACKPACK
1
10
4.0
1
1
NIL
HORIZONTAL

TEXTBOX
654
351
879
379
Harvest Level :
12
0.0
1

SLIDER
659
367
887
400
FACTOR-DIV
FACTOR-DIV
1
8
2.0
1
1
NIL
HORIZONTAL

SLIDER
659
417
889
450
HFC-TICKER-START
HFC-TICKER-START
0.1
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
658
453
890
486
HFC-TICKER-STOP
HFC-TICKER-STOP
0
0.9
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
659
485
889
518
HFC-TICKER-MAX
HFC-TICKER-MAX
1
30
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
651
401
870
431
Worrying about hungry friends:
12
0.0
1

SLIDER
707
550
892
583
PRL-TICKER-START
PRL-TICKER-START
0
0.9
0.7
0.1
1
NIL
HORIZONTAL

SLIDER
708
586
883
619
PRL-TICKER-STOP
PRL-TICKER-STOP
0.1
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
709
621
881
654
PRL-TICKER-MAX
PRL-TICKER-MAX
2
30
7.0
1
1
NIL
HORIZONTAL

TEXTBOX
662
520
901
550
Worrying about patch resource levels:
11
0.0
1

SLIDER
10
378
182
411
INCREASE-PCT
INCREASE-PCT
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
11
413
183
446
DECREASE-PCT
DECREASE-PCT
0
1
0.1
0.1
1
NIL
HORIZONTAL

TEXTBOX
21
348
171
376
Harvesting - % increase or decrease command:
11
0.0
1

TEXTBOX
1098
243
1248
273
Patches\nparameters:
12
0.0
1

SWITCH
658
311
781
344
Turtles-die?
Turtles-die?
1
1
-1000

PLOT
1666
303
1891
453
Links strength distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -14730904 true "" "histogram [ strength ] of links"

SWITCH
11
451
184
484
link-strength-impact-obey?
link-strength-impact-obey?
0
1
-1000

PLOT
1670
460
1892
610
Hubs distribution
NIL
NIL
0.0
10.0
0.0
50.0
true
false
"" ""
PENS
"default" 1.0 1 -10022847 true "" "histogram [ count turtle-group ] of turtles"

BUTTON
9
81
72
114
nw:save
save-network
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
654
58
894
91
Setup nw:load
setup2
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
653
163
771
208
strength-chooser
strength-chooser
"normal" "normal-3" "all-the-same" "exponential" "random"
1

SLIDER
775
176
891
209
link-strength
link-strength
0
10
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
785
136
935
154
when all the same:
10
0.0
1

CHOOSER
653
10
893
55
nw-filename-chooser
nw-filename-chooser
"caveman_25_16.gml" "caveman_25_15.gml" "powerlaw_cluster_400_3_03.gml" "petersen.gml"
1

PLOT
1669
619
1869
769
Betweenness Of Turtles
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -10141563 true "" "plot-turtle-centrality-betweenness"

CHOOSER
656
95
869
140
experiment-name-chooser
experiment-name-chooser
"DEMO" "CAV3" "CAV41" "CAV42" "CAV43" "CAV51" "CAV52" "CAV53" ""
0

INPUTBOX
1664
214
1933
274
experiment-name
NIL
1
0
String

BUTTON
76
82
199
115
Save data stuff
final-command2
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
<experiments>
  <experiment name="experiment#1.3 (demo)  500 turtles BACKPACK 3" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <enumeratedValueSet variable="show-link?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="500"/>
      <value value="600"/>
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment#1.4  500 turtles BACKPACK 4" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <enumeratedValueSet variable="show-link?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment#1.4(2) 500 turtles BACKPACK 4 no failing" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <enumeratedValueSet variable="show-link?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment#1.5 500 turtles Backpack 4 Depletion" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;REPORTER&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment#1.5(2) 10000 ticks 500 turtles Backpack 4 Depletion" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;REPORTER&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment#1.6 10000 ticks 500 to 300 turtles backpac" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="450"/>
      <value value="400"/>
      <value value="300"/>
      <value value="350"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;REPORTER&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment demo" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="4"/>
      <value value="3"/>
      <value value="2"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;REPORTER&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.04"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment #2.1 Network. min-degree 1 5 runs" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;REPORTER&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.16599"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-hunger-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment #3 nb-villagers link-transmission network-type" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <metric>group-turtle-hub</metric>
    <metric>link-strength-distribution</metric>
    <metric>count turtles</metric>
    <metric>count links</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="300"/>
      <value value="350"/>
      <value value="400"/>
      <value value="450"/>
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
      <value value="&quot;no-network&quot;"/>
      <value value="&quot;random_prob&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01071"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-backpack&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <metric>group-turtle-hub</metric>
    <metric>turtle-hunger-distribution</metric>
    <metric>link-strength-distribution</metric>
    <metric>count turtles</metric>
    <metric>count links</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename">
      <value value="&quot;./networks/caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;normal-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV1 caveman_25_15 link transmission 5 4 3" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <metric>group-turtle-hub</metric>
    <metric>turtle-hunger-distribution</metric>
    <metric>link-strength-distribution</metric>
    <metric>count turtles</metric>
    <metric>count links</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_15.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="5"/>
      <value value="4"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;normal-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV2 caveman_25_15 link transmission 2  1  0" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <metric>group-turtle-resource</metric>
    <metric>group-turtle-wealth</metric>
    <metric>group-turtle-prl</metric>
    <metric>group-turtle-hfc</metric>
    <metric>group-turtle-hub</metric>
    <metric>turtle-hunger-distribution</metric>
    <metric>link-strength-distribution</metric>
    <metric>count turtles</metric>
    <metric>count links</metric>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_15.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="2"/>
      <value value="1"/>
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;normal-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV3" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;CAV3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;CAV3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;normal-3&quot;"/>
      <value value="&quot;all-the-same&quot;"/>
      <value value="&quot;exponential&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV51" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;CAV51&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;CAV51&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.08"/>
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;normal-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV41" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;CAV41&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;CAV41&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.08"/>
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;normal-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV42" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;CAV42&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;CAV42&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.08"/>
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;all-the-same&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV43" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;CAV43&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;CAV43&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.08"/>
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;exponential&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV52" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;CAV52&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;CAV52&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.08"/>
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;all-the-same&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="CAV53" repetitions="5" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="10000"/>
    <exitCondition>total-resource-reporter = 0</exitCondition>
    <metric>total-resource-reporter</metric>
    <metric>total-patch-regrowth</metric>
    <metric>total-turtle-resource-reporter</metric>
    <metric>total-quantity-harvested</metric>
    <metric>number-of-hungry-turtles</metric>
    <metric>total-wealth</metric>
    <metric>total-food-exchanged</metric>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;CAV53&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;CAV53&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_16.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.08"/>
      <value value="0.1"/>
      <value value="0.12"/>
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;exponential&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-resource-ticker&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DEMO" repetitions="1" runMetricsEveryStep="true">
    <setup>setup2</setup>
    <go>go</go>
    <final>final-command</final>
    <timeLimit steps="2"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="experiment-name-chooser">
      <value value="&quot;DEMO&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DECREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="adaptive-harvest?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-BACKPACK">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nw-filename-chooser">
      <value value="&quot;caveman_25_15.gml&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INIT-HARVEST-LEVEL">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG-RATE">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="INCREASE-PCT">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debugging-agentset-nb">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-MAX">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment-name">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nb-villagers">
      <value value="79"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-link?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LINK-TRANSMISSION-DISTANCE">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-MAX">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network-type">
      <value value="&quot;preferential-attachment&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-STOP">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Turtles-die?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MIN-RSC-SAVING-PCT">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FACTOR-DIV">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TURTLE-PROC-CHOOSER">
      <value value="&quot;message&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wiring-probability">
      <value value="0.01056"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PRL-TICKER-START">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PERCENT-BEST-LAND">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-START">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="strength-chooser">
      <value value="&quot;normal-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-chooser">
      <value value="&quot;always-regrow&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MAX-TURTLE-VISION">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-strength-impact-obey?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DEBUG">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-chooser">
      <value value="&quot;turtle-connectivity&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="HFC-TICKER-STOP">
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
