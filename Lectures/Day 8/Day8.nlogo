;---------------------------------------------------INFO-------------------------------------------------------

; Caroline Cutter and Matthew Kushwaha
; Day 8 - A Simple (Simplistic) Pandemic "started" model
; Friday January 29, 2021


; GOAL:


;---------------------------------------------------NOTES-------------------------------------------------------


; GRAPHS
     ; Ver






;---------------------------------------------SAMPLE CODE FOR THE DAY-------------------------------------------------



; A tick is one day
; There is no environment or world


;-------------VARIABLES-------------


; Breeds



; Instance Variables


turtles-own [
  days-to-be-sick        ; number of days this person will have virus --- until recovery or mortality
  days-infected
  age
  sex

  mask?
  house
  isolate?
  vaccine?
  mortality-chance
  immunodeficient?

  ; Other factors? Social distancing practiced? Age? Other favtors impacting vunerability?

]






; Globals
globals [
  CLR-asymp       ; colors used to visualize a person's state with respect to the virus
  CLR-symp
  CLR-not-inf
  CLR-immune

  p-mortality       ; probability that infected persons will not recover
  p-symptomatic     ; probability of having symptoms if infected/contagious
  average-days-sick ; average time contagious until recovery or mortality
  days-to-contagion ; number of days after infected before contagious

  ; Porbabilities of infection during exposure based on who is wearing a mask
  p1     ; no masks
  p2     ; only uninfected is wearing a mask
  p3     ; only infected person has mask
  p4     ; both person has masks

  mortality-ct

  p-isolate


]





; Globals On Interface
    ;



;-------------PROCEDURES-------------



;
to setup
  ca

  reset-ticks

  init-globals
  init-world
  ;init-agents
  populate







end




to init-globals
  set CLR-asymp yellow
  set CLR-symp red
  set CLR-not-inf green
  set CLR-immune blue

  set p-mortality .02
  set p-symptomatic .50
  set average-days-sick 15
  set days-to-contagion 2

  set p1 .5
  set p2 .35
  set p3 .15
  set p4 .1

  set mortality-ct 0

  set p-isolate .5


end




to init-world
  ask patches [set pcolor grey + 2]
end


to init-agents
end



to populate
  crt population [
    setxy random-xcor random-ycor
    set color CLR-not-inf
    set days-infected -1                    ; -1 indicates not infected.
    set house patch-here

    ifelse random-float 1  < p-isolate [ set isolate? true ] [ set isolate? false ]  ; Set isolation?


    ifelse random-float 1 < mask-prob [          ;
      set mask? true
      set shape "masked-person"
    ][
      set mask? false
      set shape "person"
  ]

  ]

  initially-infect




end



; Decide mortality based off age,
to decide-mortality




end



; Decide immunodeficient based of age
to decide-immunodeficient

end









  ; ========================= main Logic of movement ====================

to go


  vaccinate-people



    ask turtles [          ; basic updates and movement, but not spreading virus

    ifelse (contagious? and isolate?) [ go-home] [wander]            ; Fix this to be inside a function



    update-infection ; check and update status of those who are infected
  ]

  new-infections       ; handle contagion



  tick

end




to initially-infect
  repeat ((percent-initially-infected / 100) * population) [ infect-one-person ]

end





to vaccinate-people
   ifelse count turtles with [ uninfected? ] < vaccines-per-tick [          ; If there are not enough, just vaccinate the rest of them
      ask turtles with [ uninfected? ] [ be-vaccinated ]
    ] [
    repeat vaccines-per-tick [ ask one-of turtles with [ uninfected? ] [ be-vaccinated ] ]        ; Else just
    ]



end













; Turtle Context
to wander
  rt ( 10 - random 21 )
  if uninfected? and [ any? turtles-here with [symptomatic?]] of patch-ahead 1 [
    if any? neighbors with [not any? turtles-here with [symptomatic?]][
      face one-of neighbors with [not any? turtles-here with [symptomatic?]]
    ]
  ]



  fd 1
end



to go-home
  move-to house
  ; Here set a circle around the person and somehow figure out how they can't infect others


end












; Turtle Context - does NOT handle interactions between turtles, only updates self turtle
to update-infection
  if days-infected >= 0 [
    set days-infected days-infected + 1

    ; is this the day that this person becomes contagious?
    if days-infected = days-to-contagion [
      ifelse random-float 1 < p-symptomatic [ become-symptomatic] [ become-asymptomatic ]
    ]

    ; is this the day that this person finishes illness?
    if days-infected = days-to-be-sick [
      ifelse random-float 1 < p-mortality [
        set mortality-ct mortality-ct + 1
        show " died of virus."
        die
      ][
        show "recovered from virus and is now immune."
        become-immune
      ]
    ]
  ]

end


; Observer Context
; Can ask to infect or be infected
; Infected are acting to infect in this situation
to new-infections
  ask turtles with [contagious?] [
    ask turtles-here with [uninfected?] [ be-exposed-by myself ]
  ]


end

; Turtle Context
; this is the procedure that handles all of the probabilites of infection
; an unifected turtle runs this procedure if exposed to virus by person p
; proability depends on mask use
; p is infected turtle
to be-exposed-by [ p ]
  if mask? and [mask?] of p            [ if random-float 1 < p4 [ be-infected ]]
  if not mask? and [mask?] of p        [ if random-float 1 < p3 [ be-infected ]]
  if mask? and not [mask?] of p        [ if random-float 1 < p2 [ be-infected ]]
  if not mask? and not [mask?] of p    [ if random-float 1 < p1 [ be-infected ]]

end





; this turtle context procedure is run when a turtle is infected with virus
to be-infected
  set days-infected 0      ; turtle infected but not yet contagious

  ; convert a random normal floating point to an appropriate integer
  let dtbs-float days-to-contagion + random-normal average-days-sick 3       ; different people are scik
  let dtbs-int int dtbs-float
  ; suppose dtbs-float = 13.3, then dtbs-int = 13, and with probability .3 we add a day
  let dtbs-carry dtbs-float - dtbs-int   ; so this is .3

  set days-to-be-sick dtbs-int
  if random-float 1 < dtbs-carry [set days-to-be-sick days-to-be-sick + 1]

end














; +===================== Helper Procedures and Reporters Turtle Context =====================



to be-vaccinated
  become-immune
  set vaccine? true
end



to become-symptomatic
  set color CLR-symp
end


to become-asymptomatic
  set color CLR-asymp
end


to become-immune
  set color CLR-immune
  set days-infected -1
end




to-report immune?
  report color = CLR-immune
end




to-report contagious?
  report color = CLR-symp or color = CLR-asymp
end


to-report symptomatic?
  report color = CLR-symp
end



; doesnt count immune
to-report uninfected?
  ; report days-infected = -1 and not immune?
  report not contagious? and not immune?
end






to infect-one-person
  ask one-of turtles with [uninfected?] [ be-infected ]


end





to-report vaccinated?
  report vaccine? = true
end



















@#$#@#$#@
GRAPHICS-WINDOW
261
10
698
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
0
0
1
ticks
30.0

BUTTON
5
10
71
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

SLIDER
15
207
188
240
population
population
200
1000
200.0
25
1
Persons
HORIZONTAL

SLIDER
16
250
188
283
mask-prob
mask-prob
0
1
0.5
.05
1
NIL
HORIZONTAL

MONITOR
39
370
126
415
NIL
mortality-ct
17
1
11

BUTTON
89
51
185
84
go forever
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
98
10
179
43
go once
go
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
25
319
165
352
infect one person
infect-one-person
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
129
222
162
percent-initially-infected
percent-initially-infected
0
100
51.0
1
1
NIL
HORIZONTAL

MONITOR
30
449
136
494
People Infected
count( turtles with [contagious?])
17
1
11

PLOT
189
511
389
661
% Population Infected
Time (ticks)
% Infected
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot ((count turtles with [contagious?]) / population) * 100"

SLIDER
784
91
1022
124
vaccines-per-tick
vaccines-per-tick
0
20
5.0
1
1
NIL
HORIZONTAL

MONITOR
24
532
148
577
People Vaccinated
count ( turtles with [vaccinated?] )
17
1
11

MONITOR
25
595
146
640
People Recovered
count (turtles with [immune?]) - count ( turtles with [vaccinated?])
17
1
11

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

masked-person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Rectangle -1 true false 105 45 195 75

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
