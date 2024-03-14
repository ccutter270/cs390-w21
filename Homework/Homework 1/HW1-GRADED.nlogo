;---------------------------------------------INFO-------------------------------------------------

; HOMEWORK 1: Graphs and Dijkstra's SSSP Algorithm

; DUE DATE: Tuesday, January 26, 2021 (by 8am)

; LAB PARTNER: Allison James

; PROFESSOR HELP: Professor Dickerson
     ; Functions from Professor Dickerson's sample codes that I modified for this HW:
         ; The random-graph and supporing functions -->  modified to create random-graphs with weights
         ; The BSF function --> modified to create Dijsktra's Algorithm (including representing it as a tree)
         ; The agent-BSF function and supporting functions --> modified to represent Dijsktra's Agent Algorithm
         ; Visit functions


; BONUS: I wasn't able to import graphs, however I gave an option for the user to create their own graphs



;---------------------------------------------CODE-------------------------------------------------






;--------------------- VARIABLES --------------------


; Breeds
breed [ vertices vertex ]
breed [ traversers traverser ]



; Instance Variables
traversers-own [ source destination speed ]
vertices-own [ visited? dist parent wgt]
links-own [ weight tree-edge? ]



; Globals
globals [ max-vertices max-edges infinity increments]
 ; Infinity represent highest possible combined weight (max-edges) * max-vertices + 1
 ; increments are used to slow traversers down



; Globals on Interface
    ; num-verticies ........ number of verticies in the graph
    ; num-edges ............ number of edges in the graph
    ; root ................. number of which vertex to be the root
    ; choose-root? ......... switch on and off
    ; visualize-SSSP? ...... switch on and off
    ; x-cor & y-cor ........ input for vertex coordinate
    ; turtle-1 & turtle-2 .. input number that represent turtle's to link
    ; weight-link .......... input weight of link




;--------------------------------------------- STARTER PROCEDURES-------------------------------------------------


; Observer Context
; sets background and globals
to setup
  ca
  ask patches [set pcolor black]

  ; set globals
  set max-vertices 100
  set max-edges 200
  set infinity (max-vertices * max-edges) + 1
  set increments 10000

  ; set root
  ifelse choose-root?
      [ set root root]                             ; if choose-root? is true, set root to global root
      [ set root (random num-vertices)]            ; else, set random root
end




;----------------------------- General Helper Procedures ---------------------


; Observer Context
; Resets graph by resetting verticies, links and asking traversers to die
to reset-graph
  ask vertices [
    set color white
    set size .5
    set visited? false
    set parent self
    set wgt 0
    set dist infinity
  ]
  ask links [
    set color white
    set thickness 0
    set tree-edge? false
  ]
  ask traversers [die]
end


; Turtle Context
; Visits the turtle
to be-visited
  set visited? true
  set color red
  set size .75
end


; Observer Context
; Asks turtle v to be-visited
to visit [ v ]
  ask v [be-visited ]
end



;------------------------------------------- Own-Graph PROCEDURES-----------------------------------------------

; Observer Context
; Adds vertecies based of user input
to add-vertex [ x y ]
  create-vertices 1 [
    set parent self
    set visited? false
    set dist infinity
    set shape "circle"
    set size .5
    set color white
    set label-color red
    set label (word who "      ")
    setxy x y
  ]
end


; Observer Context
; Makes turtle (number t) die
to delete [ t ]
  ask turtle t [ die ]
end







;------------------------------------------- random-graph PROCEDURES-----------------------------------------------


; Observer Context
; Creates a random graph based of user input of vertices and edges
; Adjust vertices and edges accordingly, then creates graph and spreads vertices out
to random-graph [ n m ]

  setup

  ; If there are no vertices
  if n <= 0 [
    write (word "Can't create a graph without vertices. Setting n = 1")
    set n 1
  ]

  ; If too many edges to vertices, sets m to max amount of edges
  if m > n * ( n - 1) / 2 [
    write ( word "Can't create a graph with " m " edges and " n " verticies. Adjusting m to max.")
    set m ( n * (n - 1 )) / 2
  ]

  ; If not enough edges, sets m to min amount of edges
  if m < n - 1 [
    write ( word "Need " (n - 1) " edges to make a connected graph. Adjusting m ...")
    set m n - 1
  ]

  ; makes random graph
  make-vertex-set n
  make-edge-set n m

  repeat 30 [ layout-spring vertices links .5 15 2 ]          ; Spreads vertices out

end



;----------- Helper Procedures (random-graph) -----------

; Observer Context
; Makes n vertices, sets instance variables accordingly
to make-vertex-set [ n ]
  create-vertices n [
    set parent self
    set visited? false
    set dist infinity
    set shape "circle"
    set size .5
    set color white
    set label-color red
    set label (word who "     ")
    setxy random-xcor random-xcor
  ]
end



; Observer Context
; Makes edges between vertices with random weights
; Ensures every vertex is connected and there are no cycles
to make-edge-set [ n m ]

  ask one-of vertices [ set-up-link (self) (one-of other vertices)] ; First link

  repeat ( n - 2 ) [                                                ; Repeats until each vertex has an edge                                                                            ; Connects unconnected vertices
    ask one-of vertices with [any? my-links] [
      let neigh [who] of (one-of vertices with [not any? my-links])
      set-up-link (self) (vertex neigh)
    ]
  ]

  repeat (m - (n - 1)) [                                              ; Repeats for remaining edges
    ask one-of vertices with [count my-links < n - 1] [
      let neigh [who] of (one-of other vertices with [not link-neighbor? myself])
      set-up-link (self) (vertex neigh)
    ]
  ]
end



; Turtle Context
; x , y -> vertices
; Sets up a link with a random weight between x & y
to set-up-link [ x y ]
  ask x [create-link-with y ]                 ; Create link
  ask link ([who] of x) ([who] of y) [        ; Give link characteristics
    set weight (random 99 + 1)                ; Random edge weights 1-100 inclusive
    set label weight
    set label-color white
  ]
end




; ---------------------------------------------- dijkstra PROCEDURES---------------------------------------------




 ;Observer Context
 ;[ root-chosen ]-> turtle designated as root
 ; Performs dijkstra's algorithm on the graph on the interface
 ; Starts from the root from the user and visits all edges
to dijkstra [ root-chosen ]

  reset-graph

  ask root-chosen [set dist 0 ]                             ; d(r) = 0
  visit root-chosen

  let queue [ ]                                            ; Create queue with all vertices
  ask vertices [
    set queue lput self queue
  ]

  while [ any? vertices with [ visited? = false ]] [       ; While any vertices remain unvisited

    let v first queue                                      ; let v be the unvisited node minimizing d(v)
    let index 0

    foreach queue [                                            ; find node with smallest distance (v)
      [ node ] ->
      if ([dist] of node) < ([dist] of v) [

         set v node
         set index ( position v queue)
      ]
    ]

    set queue remove-item index queue                       ; mark v as visited (and remove from queue)
    visit v

    ask ( [link-neighbors] of v ) [                         ; for all edges (v, w)

       let w self ; w is link-neighbor

       let x [who] of v ; number of v
       let y [who] of w ; number of w

       let link-weight   ([weight] of link x y )             ;  W (v,w)
       let vertex-dist ([dist] of v)                         ;  d(v)
       let neighbor-dist ([dist] of w)                       ;  d(w)

       if (vertex-dist + link-weight) < neighbor-dist [     ; if d(v) + Weight(v, w) < d(w)
           set dist (vertex-dist + link-weight)
           set parent v                                     ; set new weight and parent

           ask [ link-neighbors ] of w [                    ; Decolor previous links
              let a [who] of self ; w
              let b [who] of w    ; link-neighbor
              ask link a b [ set color white set thickness 0 set tree-edge? false]
           ]
           ask link x y [ set color red set tree-edge? true set thickness .25]        ; Color new link
        ]
     ]
  ]
  if visualize-SSSP? [ layout-radial vertices links with [tree-edge?] root-chosen]

end






; ---------------------------------------- dijkstra-agent PROCEDURES----------------------------------------------


; Observer Context
; [ root-chosen ] -> turtle designated as root
; Agent-Based dijkstra's algorithm launches traversers to find shortest path to each vertex
; using edge weights as the steps for each traverser (increment were added to make the visualization better)
to agent-dijkstra [ root-chosen ]

  reset-graph

  visit root-chosen                                       ; visit root
  launch-traversers-from root-chosen                      ; launch traversers from the root

  while [ any? traversers ][ move-traversers ]            ; move traversers until completed

  if visualize-SSSP? [ layout-radial vertices links with [tree-edge?] root-chosen ]

end



;----------- Helper Procedures for agent-dijkstra ---------


; Turtle Context
; [ v ] -> a vertex
; Asks a vertex (v) to launch traversers to their neighbors by going backwards from neighbors
; Speed is based of weight of the links
to launch-traversers-from [ v ]

  ask ([link-neighbors] of v) [

    let x [who] of self ; link neighbor
    let y [who] of v ; source
    ask self [ set wgt ([weight] of link x y)]         ; Ask neighbors to set wgt to link weight

    launch-traversers-toward-me-from v                 ; Link neighbors launch traversers towards themsleves from v
  ]
end




; Turtle Context
; [ v ] -> a vertex
; Creates traversers, sets source as v and destination as v's neighbors, sets speed based of weight
to launch-traversers-toward-me-from [ v ]
    hatch-traversers 1 [
      set size 1
      set color green
      set label ""
      set source v
      setxy [xcor] of source [ycor] of source
      create-link-with source [ set color green set thickness .25 ]
      set destination myself                                           ; myself = link-neighbor = destination
      face destination
      set speed ((distance destination) / ([wgt] of destination)) / increments ; speed = (dist / wgt) / increments
  ]
end




; Observer Context
; Moves traversers one step based of their speed
; If traversers reach their destination, destination becomes v and launches traversers from itself
; If a destination vertex is visited while the traverser is still in-route, that traverser dies
to move-traversers

  ask traversers [

    if ( [visited?] of destination = true ) [ die ]             ; if target is visited, die

    fd speed

    if (distance destination <= .00001 ) [                         ; if reached destination

      visit destination                                         ; visit, set new parent, color

      ask destination [
        set parent ([source] of myself )
        ask link-with [source] of myself [ set color red set thickness .25  set tree-edge? true]
        launch-traversers-from self
      ]
      die
    ]
  ]
end




@#$#@#$#@
GRAPHICS-WINDOW
253
10
690
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
0
0
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
70
15
136
48
Setup
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

SWITCH
743
104
884
137
choose-root?
choose-root?
0
1
-1000

BUTTON
30
186
188
219
Make Random Graph
random-graph num-vertices num-edges
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
23
100
195
133
num-vertices
num-vertices
1
max-vertices
9.0
1
1
NIL
HORIZONTAL

SLIDER
23
140
195
173
num-edges
num-edges
1
max-edges
14.0
1
1
NIL
HORIZONTAL

SLIDER
730
166
902
199
root
root
0
num-vertices - 1
0.0
1
1
NIL
HORIZONTAL

BUTTON
743
299
891
332
Dijkstra's Algorithm
dijkstra turtle root
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
734
230
884
263
visualize-SSSP?
visualize-SSSP?
1
1
-1000

TEXTBOX
757
67
907
95
Choose Root: On\nRandom Root: Off
11
0.0
1

TEXTBOX
761
146
911
164
If On, Choose Root: 
11
0.0
1

BUTTON
734
339
903
372
Dijkstra's Agent Algorithm
agent-dijkstra (vertex root)
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
760
210
910
228
Tree Visualization?
11
0.0
1

TEXTBOX
761
274
911
292
Algorithm Options: 
11
0.0
1

INPUTBOX
117
304
167
364
y-cor
5.0
1
0
Number

INPUTBOX
50
304
100
364
x-cor
9.0
1
0
Number

BUTTON
63
376
164
409
Add Vertex
add-vertex  x-cor y-cor 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
26
469
76
530
turtle-1
3.0
1
0
Number

INPUTBOX
84
469
134
529
turtle-2
1.0
1
0
Number

BUTTON
74
542
160
575
Add Link
set-up-link (vertex turtle-1) (vertex turtle-2)\n\nask link turtle-1 turtle-2 [ \n   set weight weight-link\n   set label weight\n   ]
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
13
243
219
281
CREATE YOUR OWN GRAPH:
14
0.0
1

TEXTBOX
17
280
167
298
1. Add Vertices:
12
0.0
1

TEXTBOX
16
425
166
443
2. Add Links: 
12
0.0
1

TEXTBOX
39
444
216
472
** all vertices must be linked **
11
0.0
1

TEXTBOX
27
69
201
103
MAKE RANDOM GRAPH:
14
0.0
1

TEXTBOX
758
26
908
44
FUNCTIONS: 
14
0.0
1

TEXTBOX
268
465
418
483
In case you made a mistake: 
11
0.0
1

INPUTBOX
301
486
380
546
delete-turtle
0.0
1
0
Number

BUTTON
397
496
507
529
Delete Turtle
delete delete-turtle
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
147
469
220
529
weight-link
15.0
1
0
Number

@#$#@#$#@
## GRADING:

There is a divide-by-zero run-time error on the manually created graphs. 
The user interface looks very nice. 
Although it's good that you learned to use the foreach command, the way you are using it doesn't make sense.  That code is doing a linear search on a list.  Just doing a min-one-of on the agent set gets the same result also as a linear search but avoids the extra work of creating a list-queue. No reason to create a queue unless you are implementing a priority queue that works in log n time.

Correctness and Functionality:  57/60
Style and structure:   15/20
Netlogo primitives:	10/10
Commenting:       10/10
Bonus:   +3                   -- allows manually created graph



TOTAL:  95/100
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
