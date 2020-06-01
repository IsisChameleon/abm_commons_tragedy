
# Reporters for experiments:
==========================

total-resource-reporter
total-patch-regrowth
total-turtle-resource-reporter
total-quantity-harvested
number-of-hungry-turtles
total-wealth
group-turtle-resource
group-turtle-wealth
group-turtle-prl 
group-turtle-hfc


# SERIES #1 OF experiments
========================
========================




## Parameters for experiments:
==============================
## #1.3
["show-link?" true]
["nb-villagers" 500]
["LINK-TRANSMISSION-DISTANCE" 1]
["min-degree" 2]
["adaptive-harvest?" true]
["network-type" "preferential-attachment"]
["MIN-RSC-SAVING-PCT" 3]
["debugging-agentset?" true]
["wiring-probability" 0.16599]
["regrowth-chooser" "always-regrow"]
["INIT-HARVEST-LEVEL" 1]
["DEBUG-RATE" 0.05]
["DEBUG" false]
["debugging-agentset-nb" 1]
["color-chooser" "turtle-hunger-ticker"]
* PERCENT-BEST-LAND 0.06


MAX-TURTLE-VISION 8
MAX-TURTLE-BACKPACK 3 ;;<<<<<<<<<<<<<<<<< this one is varied

FACTOR-DIV 4

HFC-TICKER-START 0.5
HFC-TICKER-STOP 0.3
HFC-TICKER-MAX 10
PRL-TICKER-START 0.5
PRL-TICKER-STOP 0.7 
PRL-TICKER-MAX 10
INCREASE-PCT 0.1
DECREASE-PCT 0.1

MAX-TURTLE-HARVEST 5
MIN-TURTLE-HARVEST 2
MIN-TURTLE-HUNGER 2 
MAX-ON-BEST-PATCH 100
PATCH-MIN-TO-REGROW 0.5
PATCH-REGROWTH-RATE 0.15
PATCH-DECAY-RATE 0.2
MAX-LINK-STRENGTH 10
MIN-TURTLE-DISTANCE 2
MWF-TICKER-MAX 20
FNP-TICKER-MAX 20
FIND-NEW-PLACE-PCT 0.1

Parameters for experiments:
## #1.4
["show-link?" true]
["nb-villagers" 500]
["LINK-TRANSMISSION-DISTANCE" 1]
["min-degree" 2]
["adaptive-harvest?" true]
["network-type" "preferential-attachment"]
["MIN-RSC-SAVING-PCT" 3]
["debugging-agentset?" true]
["wiring-probability" 0.16599]
["regrowth-chooser" "always-regrow"]
["INIT-HARVEST-LEVEL" 1]
["DEBUG-RATE" 0.05]
["DEBUG" false]
["debugging-agentset-nb" 1]
["color-chooser" "turtle-hunger-ticker"]
PERCENT-BEST-LAND 0.06
MAX-TURTLE-BACKPACK 4 ;;<<<<<<<<<<<<<<<<< this one is varied
MIN-TURTLE-DISTANCE 2
FIND-NEW-PLACE-PCT 0.1
MAX-TURTLE-VISION 8
MAX-ON-BEST-PATCH 100
PATCH-MIN-TO-REGROW 0.5
PATCH-REGROWTH-RATE 0.15
PATCH-DECAY-RATE 0.2
MWF-TICKER-MAX 20
FNP-TICKER-MAX 20
MIN-TURTLE-HUNGER 2 
MAX-TURTLE-HARVEST 5
MIN-TURTLE-HARVEST 2
FACTOR-DIV 4
MAX-LINK-STRENGTH 10
HFC-TICKER-START 0.5
HFC-TICKER-STOP 0.3
HFC-TICKER-MAX 10
PRL-TICKER-START 0.5
PRL-TICKER-STOP 0.7 
PRL-TICKER-MAX 10
INCREASE-PCT 0.1
DECREASE-PCT 0.1

## #1.5   500 turtles backpack 4 land depletion 500 ticks limiti


Run #1 of 1, step #171
Total elapsed time: 0:00:30
DECREASE-PCT = 0.1
min-degree = 2
adaptive-harvest? = true
MAX-TURTLE-BACKPACK = 4
debugging-agentset? = true
INIT-HARVEST-LEVEL = 1
DEBUG-RATE = 0.05
INCREASE-PCT = 0.1
debugging-agentset-nb = 1
HFC-TICKER-MAX = 10
show-link? = false
nb-villagers = 500
LINK-TRANSMISSION-DISTANCE = 1
PRL-TICKER-MAX = 10
network-type = preferential-attachment
PRL-TICKER-STOP = 0.7
HFC-TICKER-START = 0.5
MIN-RSC-SAVING-PCT = 3
FACTOR-DIV = 4
TURTLE-PROC-CHOOSER = REPORTER
wiring-probability = 0.16599
PRL-TICKER-START = 0.5
PERCENT-BEST-LAND = 0.6
regrowth-chooser = always-regrow
MAX-TURTLE-VISION = 8
DEBUG = false
color-chooser = turtle-hunger-ticker
HFC-TICKER-STOP = 0.3

## #1.5(2) same as 1.5 with 10 000 ticks limit


## #1.6 What happens when incresaing turtles number

["DECREASE-PCT" 0.1]
["min-degree" 2]
["adaptive-harvest?" true]
["MAX-TURTLE-BACKPACK" 4]
["debugging-agentset?" true]
["INIT-HARVEST-LEVEL" 1]
["DEBUG-RATE" 0.05]
["INCREASE-PCT" 0.1]
["debugging-agentset-nb" 1]
["HFC-TICKER-MAX" 10]
["show-link?" false]
["nb-villagers" 450 400 300 350 300]
["LINK-TRANSMISSION-DISTANCE" 1]
["PRL-TICKER-MAX" 10]
["network-type" "preferential-attachment"]
["PRL-TICKER-STOP" 0.7]
["HFC-TICKER-START" 0.5]
["MIN-RSC-SAVING-PCT" 3]
["FACTOR-DIV" 4]
["TURTLE-PROC-CHOOSER" "REPORTER"]
["wiring-probability" 0.16599]
["PRL-TICKER-START" 0.5]
["PERCENT-BEST-LAND" 0.06]
["regrowth-chooser" "always-regrow"]
["MAX-TURTLE-VISION" 8]
["DEBUG" false]
["color-chooser" "turtle-hunger-ticker"]
["HFC-TICKER-STOP" 0.3]

