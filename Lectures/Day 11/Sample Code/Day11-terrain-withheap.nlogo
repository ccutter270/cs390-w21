; Inclass Demo -- synthetic terrain models
; Matthew Dickerson, CSCI390
; v 3.0 -- this version uses an array-based heap to implement a priority queue to keep track of the beach line in growing ponds.

__includes [ "heap2.nls"]

globals [
  min-elev max-elev      ; global variables to show the desired range of elevations in a randomized terrain
  pond-ct                ; the count of the number of ponds we have found so far
  water-clr              ; a constant to hold the color of water
]

patches-own [
  elevation              ; i.e. altitude, used for a terrain model. Units are feet above sea level
  is-edge?               ; true if on the edge of the world, false otherwise
  has-outlet?            ; true if not a local minimum -- if water would flow out of this patch
  outlet                 ; where would water on this patch flow
  pond                   ; if pond = 0, this is not a water body. Otherwise all patches in the same pond/lake
                         ; have the same number
  pond-queue             ; shows if this pond has been put into the beach pq of a pond
  river?                 ; set to true if this patch has been identified as a river
  depth
]


to setup
  ca
  init-globals
  create-terrain
end

to init-globals
  set min-elev 500
  set max-elev 1500
  set water-clr (blue + 3)
end

; OBSERVER
; Create an artificial terrain model
to create-terrain
  ask patches [ set elevation random-float 1.0 ]             ; randomize elevations  (note: the range doesn't matter)
  repeat 100 [ diffuse elevation .65 ]                       ; smooth elevations to create a natural terrain
  normalize                                                  ; normalize and color the terrain model

  ; If the terrain-type is not flat, adjust the terrain to put in some slopes
  if terrain-type = "ns ridge" [ make-ridge]
  if terrain-type = "slope" [make-slope]
  if terrain-type = "peak" [make-peak]

  ask patches [ set pcolor scale-color green elevation min-elev max-elev ]
end

to make-ridge
  ask patches [ set elevation elevation - 10 * (abs pxcor) ]
  set min-elev (min-elev - 10 * max-pxcor )
end

to make-slope
  ask patches [ set elevation elevation - 5 * (max-pycor - pycor) ]
  set min-elev (min-elev - 5 * world-height )
end

to make-peak
  ask patches [ set elevation elevation - 10 * distance patch 0 0 ]
  set min-elev [elevation] of min-one-of patches [elevation]
end


; OBSERVER
; Scale the elevations of patchs to fit in the desired range determined by min-elev and max-elev
to normalize
  let delta-e (max-elev - min-elev)                              ; elevation difference in the desired terrain model
  let temp-max [elevation] of max-one-of patches [elevation]     ; the actual lowest, highest, and difference in the current pre-normalized world
  let temp-min [elevation] of min-one-of patches [elevation]
  let temp-dif temp-max - temp-min
  ask patches [ set elevation ((elevation - temp-min) * (delta-e / temp-dif) + min-elev) ]   ; the normalizing step
end

to rain
  crt 20 [
    set color blue
    set size 1
    setxy random-xcor random-ycor
    set shape "circle"
  ]
  ask turtles [
    if is-edge? [die]
    if (pond != 0) and ([pond] of outlet = pond) [move-to outlet]
    face outlet
    fd .3
  ]
end


; OBSERVER CONTEXT
; Grow a pond around all patches that can hold water (patches surrounded by higher patches)
to grow-ponds
  set pond-ct 0
  ask patches [ set pond 0 set pond-queue 0 set river? false]
  ask patches with [ not is-edge? and not has-outlet? ][
    ifelse use-pqueue? [ grow-pond ][ grow-pond-bruteforce ]
  ]
end

; PATCH CONTEXT -- should be run by a patch that is a local minimum to form a pond around it
; a patch that is a local minimum grows a lake around it by filling in with water
; this version uses a pq to store the "beach line" of a growing pond--the next patch to be considered for addition.
to grow-pond
  init-pond-bottom

  ; Initialize the beach: the priority queue of patches adjacent to this growing pond, to be considered for addition to the pond.
  ; NOTE: patches in this queue should have pond-queue = pond-ct and should not be readded to this queue
  let beach new-pqueue [[ p1 p2] -> [elevation] of p1 < [elevation] of p2]
  ask neighbors [                     ; these are the neighbors of the patching running this -- the bottom of this pond
    set beach insert beach self       ; they are all candidates to be added to the pond
    set pond-queue pond-ct            ; this is used to keep patches from behind added to the queue more than once
  ]

  ; remove the next-lowest patch from the beach to see whether it should be the pond outlet, or get added to the growing pond
  let next-lowest report-min beach
  set beach delete-min beach

  ; if the next-lowest patch is not on the edge, and it flows back into the pond, then it is not an outlet and the pond keeps growing
  while [ (not [is-edge?] of next-lowest) and ([pond] of ([outlet] of next-lowest) = pond-ct) ] [
    ; If next-lowest patch is part of a previously filled pond, then this new pond floods (takes over) the existing pond. All the patches
    ; of the existing pond get added to this pond, and all their neighbors are part of the beach.
    if [pond] of next-lowest != 0 [
      ask patches with [pond = [pond] of next-lowest][
        set pond pond-ct
        if plabel != "" [set plabel pond]
        ask neighbors with [pond = 0 and pond-queue != pond-ct] [
          set beach insert beach self
          set pond-queue pond-ct
        ]
      ]
    ]

    ; this is the step that adds the next-lowest patch from the beach to the pond, and adds its neighbors to the beach
    ask next-lowest [
      set pond pond-ct
      set pcolor water-clr
      ; neighbors not yet in the queue and not yet in this pond should be added to the beach
      ask neighbors with [pond != pond-ct and pond-queue != pond-ct] [
        set beach insert beach self
        set pond-queue pond-ct
      ]
    ]

    ; get the next candidate and continue
    set next-lowest report-min beach
    set beach delete-min beach
  ]

  ; when the above loop is finished, it means we have found the outlet of the pond, which is next-lowest.
  ask patches with [pond = pond-ct ][
    set outlet next-lowest
    set has-outlet? true
  ]
  ask next-lowest [ set pond pond-ct  set pcolor red ]
end


to grow-pond-bruteforce
   ; print (word "Making a pond from " self)
   set pond-ct pond-ct + 1         ; Update the global count used to number each pond
   set pond pond-ct            ; Label this patch with its new pond number
   let mypond patch-set self         ; Keep a list of all the patches that become part of this pond
   set pcolor blue + 2           ; Color the patch appropriately

   ; Keep track of all the possible patches that might be part of this pond.
   ; All neighbors or current pond patches are considered in increasing order of altitude.
   let inlets neighbors

   ; Get the lowest patch from the "inlets" list of potential pond patches, and remove it from the list
   let lowest-inlet min-one-of inlets [elevation]
   set inlets inlets with [self != lowest-inlet]

   ; Keeping adding patches to this pond until one is found that has an outlet that is not already full of water.
   ; Any neighboring patch that flows into this pond can become part of this pond as the water level goes up.
   while [ [pond] of ([outlet] of lowest-inlet) = pond-ct][
     ; If this pond keeps growing upward and overtakes another pond that currently flows into it, that other pond
     ; will become a part of this pond.

     set mypond (patch-set mypond lowest-inlet)                                  ; Add the new patch to this pond
     ask lowest-inlet [                                                      ; Update that patch, and adds its neighbors to "inlets"
       set inlets (patch-set inlets neighbors with [pond != pond-ct])
       set pond pond-ct
       set pcolor blue + 2
     ]

     ; Get the next potential patch for this pond
     set lowest-inlet min-one-of inlets [elevation]
     set inlets inlets with [self != lowest-inlet]
   ]
   ; When this loop ends, the patch called "lowest-inlet" is the outlet.

   ; When all the patches for this pond are found, make sure they all point to the outlet patch of the pond so that all water
   ; flowing into the pond will flow out in the correct place.
   ask mypond [
     set outlet lowest-inlet
     set has-outlet? true
     set depth ([elevation] of lowest-inlet) - elevation
   ]
end
;; PATCH CONTEXT -- should be run by a patch that is a local minimum to form a pond around it
;; a patch that is a local minimum grows a lake around it by filling in with water
;; this version uses a pq to store the "beach line" of a growing pond--the next patch to be considered for addition.
;to grow-pond-bruteforce
;  init-pond-bottom
;
;  ; Initialize the beach: the priority queue of patches adjacent to this growing pond, to be considered for addition to the pond.
;  ; NOTE: patches in this queue should have pond-queue = pond-ct and should not be readded to this queue
;  let beach neighbors4 with [pond = 0]
;
;  ; remove the next-lowest patch from the beach to see whether it should be the pond outlet, or get added to the growing pond
;  let next-lowest min-one-of beach with [pond != [pond] of myself] [ elevation ]
;  set beach delete-min beach
;
;  ; if the next-lowest patch is not on the edge, and it flows back into the pond, then it is not an outlet and the pond keeps growing
;  while [ (not [is-edge?] of next-lowest) and ([pond] of ([outlet] of next-lowest) = pond-ct) ] [
;    ; If next-lowest patch is part of a previously filled pond, then this new pond floods (takes over) the existing pond. All the patches
;    ; of the existing pond get added to this pond, and all their neighbors are part of the beach.
;    if [pond] of next-lowest != 0 [
;      ask patches with [pond = [pond] of next-lowest][
;        set pond pond-ct
;        if plabel != "" [set plabel pond]
;        ask neighbors with [pond = 0 and pond-queue != pond-ct] [
;          set beach insert beach self
;          set pond-queue pond-ct
;        ]
;      ]
;    ]
;
;    ; this is the step that adds the next-lowest patch from the beach to the pond, and adds its neighbors to the beach
;    ask next-lowest [
;      set pond pond-ct
;      set pcolor water-clr
;      ; neighbors not yet in the queue and not yet in this pond should be added to the beach
;      ask neighbors with [pond != pond-ct and pond-queue != pond-ct] [
;        set beach insert beach self
;        set pond-queue pond-ct
;      ]
;    ]
;
;    ; get the next candidate and continue
;    set next-lowest report-min beach
;    set beach delete-min beach
;  ]
;
;  ; when the above loop is finished, it means we have found the outlet of the pond, which is next-lowest.
;  ask patches with [pond = pond-ct ][
;    set outlet next-lowest
;    set has-outlet? true
;  ]
;  ask next-lowest [ set pond pond-ct  set pcolor red ]
;end

to make-all-rivers
  ask patches with [ pond != 0 and not is-edge? and [pond] of outlet != pond ] [make-river]
end

to make-river
  let next outlet
  while [ not [is-edge?] of next and [pond] of next = 0 ][
    ask next [ set pcolor blue set river? true ]
    set next [outlet] of next
  ]
end

to make-a-spring
  while [not mouse-down?][]
  while [mouse-down?][]
  ask patch mouse-xcor mouse-ycor [
    if pond = 0 [
      make-river
    ]
  ]
end

to init-pond-bottom
  ; update the patch forming a pond to be part of the pond, and initialize the other patches
  set pond-ct pond-ct + 1       ; global variable that counts ponds. We have just started a new pond
  set pond pond-ct
  set plabel-color black
  set plabel pond
  set pcolor water-clr
end

; for every patch, label whether it is an edge, and if not whether it has another lower neighboring patch (outlet)
; and what that is.
to find-outlets
  ask patches [
    set is-edge?  ( pxcor = max-pxcor or pycor = max-pycor or pxcor = min-pxcor or pycor = min-pycor )
    let lowest-neighbor min-one-of neighbors [elevation]
    ifelse elevation > [elevation] of lowest-neighbor [
      set has-outlet? true
      set outlet lowest-neighbor
    ][
      set has-outlet? false
      set outlet self
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
239
10
2049
981
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-450
450
-240
240
0
0
1
ticks
30.0

BUTTON
25
28
158
62
1. Make a terrain
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

BUTTON
33
309
97
343
NIL
rain
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
34
354
173
399
terrain-type
terrain-type
"flat" "ns ridge" "slope" "peak"
0

BUTTON
35
411
163
445
NIL
make-all-rivers
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
34
453
159
487
NIL
make-a-spring
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
24
204
162
237
use-pqueue?
use-pqueue?
0
1
-1000

BUTTON
23
66
174
99
2. Process Downhill
find-outlets
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
22
104
196
137
3. Raise the Water Level
grow-ponds
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
32
149
182
167
Do these in order: 1...2...3...
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.2.0
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
