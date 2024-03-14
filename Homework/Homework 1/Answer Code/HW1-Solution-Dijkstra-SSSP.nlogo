; Matthew Dickerson
; HW1 Sample Solution
; ----------------
; An implementation of two SSSP algorithms.
;
; 1) The standard Dijkstra SSSP algorithm.
; Note that this is not nessecarily the most asymptotically efficient implementation (depending on relative values of m and n).
; This version uses the min-one-of operator to find the next vertex -- the vertex v with minimum d[v]. On a list of n vertices,
; the min-one of requires O(n) time, and it takes O(1) time to update d[v] after a link is checked..
; Alterately, a priority queue such as a heap with updatable values could accomplish this wiht O(log(n)) time for both delete-min
; and update operations.
; Since each edge may results in an udpate to the d[v] value (if it finds a shorter path), using a priority queue results in a
; O(nlogn+mlogn) algorithm.  This approach requires O(m+n^2) which is slower for sparse graphs (when m is less than n^2) but can
; be faster for dense graphs (when m is on the order of n^2).
;
; 2) An agent-based SSSP that finds the shortest path from a root to all other vertices by sending agents out in parallel along all
; possible paths, and continuing to spawn more agents at all vertices to continue to follow all edges to all unvisited vertices,
; at speeds that require time proportional to the weight of an edge.  The first agent to reach a vertex represents
; a shortest possible path.


breed [vertices vertex]                          ; A graph vertex
breed [searchers searcher]                       ; An agent that can search a single graph edge in the agent-based SSSP.

vertices-own [
  visited?                                       ; used to mark vertices in a search algorithm
  parent                                         ; shows the parent of the vertex in a search tree
  best-d                                         ; total weight of best-known path from root to this vertex so far (for Dijkstra SSSP)
  name
]
links-own [                                      ; links are used to represent graph edges
  tree-edge?                                     ; set to true if this link is an edge in a search tree
  weight                                         ; a positive integer from 1..max-edge-weight
]
searchers-own [
  source                                         ; a searcher follows an edge of the graph from source vertex to destination vertex
  destination
  speed                                          ; can be used to control the speed that a searcher moves along an edge for visualization
  steps                                          ; used to count down from weight of edge to 0, for an controlling movement along an edge.
]

; globals
globals [
  increments                                     ; number of steps for a searcher to traverse one edge unit.
                                                 ; this increments * weight of an edge is number of steps to traverse that edge
  infinity                                       ; constant represents infinity
  max-edge-weight                                ; see the weight of a graph edge
]

;Globals defined in the interface
; num-vertices -- defined by a slider
; num-edges    -- defined by a slider
; visualize-bfs-tree?  -- defined by switch


to setup
  ca
  set increments 20000                  ; initialize globals
  set max-edge-weight 100
  ; set increments 1
  ask patches [set pcolor white]
end


;========================== BFS PROCEDURES ============================

; Standard BFS just using the graph structure, starting at the given root
; Note one difference between a BFS and a DFS is that in a BFS you visit a vertex before putting it in the queue
; while in a DFS you visit a vertex at the start of the recursive call to that vertex
to D-SSSP [ root ]
  reset-graph

  ask vertices [set best-d infinity set parent self]
  ask root [set best-d 0]

  while [ any? vertices with [not visited?]][
    let v min-one-of (vertices with [not visited?]) [best-d]
    visit v
    ask v [show " is being visited."]
    if v != root [
      ask [parent] of v [ ask link-with v [set color red set thickness .25]]
    ]

    ask ([link-neighbors] of v) with [not visited?][
      show (word " is being updated by " v)
      let wt [weight] of link-with v
      if (wt + [best-d] of v < best-d) [
        set best-d (wt + [best-d] of v)
        set parent v
      ]

    ]
  ]

  ; a radial layout will help show the structure of the BFS tree.
  if visualize-SSSP-tree? [ layout-radial vertices links with [tree-edge?] root ]
end


; ========================== AGENT-BASED BFS PROCEDURES ============================

; In an agent-based BFS, instead of a queue to hold all of the vertices waiting to be processed, we create an agent for each of those
; vertices. All the searcher agents will move in (simulated) parallel, all reaching their destinations at the same time, and then all
; launching a new set of searcher agents to reach the next level of vertices in the BFS
to agent-sssp [ root ]
  reset-graph

  ; To start search, visit the root and launch searchers toward all of its neighbors
  visit root
  launch-searchers-from root

  ; move the searchers until no searchers are left -- equivalent of an empty queue
  while [ any? searchers ][  move-searchers ]

  ; a radial layout will help show the structure of the BFS tree.
  if visualize-SSSP-tree? [ layout-radial vertices links with [tree-edge?] root ]
end

; ------------- HELPER PROCEDURES ----------------

; searchers take the part of the BFS queue, so launch-searchers-from takes the place of adding all the unvisited neighbors to a queue.
; This procedure launches searchers from a vertex v to all its unvisited neighbors. Note that as soon as searcher is launched toward
; a vertex, it should be marked as visited so no other searchers get sent there.  This is equivalent to marking a vertex as visited when
; it is put into the BFS queue.
to launch-searchers-from [ v ]
  ask ([link-neighbors] of v) with [not visited?] [
    launch-searcher-toward-me-from v
  ]
end

; vertex context
; This procedure launches a single vertex from v toward the vertex performing this procedure
to launch-searcher-toward-me-from [ v ]
    hatch-searchers 1 [
      set shape "person"
      set color green
      set source v
      setxy [xcor] of source [ycor] of source
      create-link-with source [ set color yellow set thickness .15 ]
      set destination myself
      face destination
      let wt [weight] of ([link-with v] of destination)
      set speed (distance destination) / ( wt * increments )
      set steps wt
    ]
end

; Move all the searchers incrementally to their next destination
; Since edges are treated as unweighted, all searchers will arrive at next destination at same iteration
to move-searchers
  repeat increments [ ask searchers [ fd speed ]]     ;  all searchers go forward one unit

  ask searchers [
    ; only the first searcher to reach a vertex counts -- this is guarantees that the minimum distance is found
    if [visited?] of destination [die]

    set steps (steps - 1)                             ; decrement the steps counter
    if steps = 0     [                                ; if destination has been reached
      ask destination [                               ; the destination has not been visited
        set visited? true
        set parent [source] of myself
        ; mark the edge that was followed as a tree edge, and launch searchers to unvisited neighbors
        ask link-with [source] of myself [ set color red set thickness .25 set tree-edge? true]
        launch-searchers-from self
      ]
      die
    ]
  ]
end




; ================ OBSERVER CONTEXT HELPER PROCEDURES FOR GRAPH ALGORITHMS =============

; reset coloring and visited? variables of the graph (both vertices and edges)
; for use after a search
to reset-graph
  ask vertices [ set color black set size .5 set visited? false set parent self]
  ask links [set color gray set thickness 0 set tree-edge? false]
  ask searchers [ die ]
end


; Mark a vertex as visited.
; for use in a BFS, DFS, or other algorithm that needs to mark visited vertices.
to visit [ v ]
  ask v [ be-visited ]
end

; ================ VERTEX CONTEXT HELPER PROCEDURES FOR GRAPH ALGORITHMSS =============
; a vertex visits itself
to be-visited
  set visited? true
  set color red
  set size .75
end


; ================= OBSERVER CONTEXT PROCEDURES TO CREATE A RANDOM GRAPH ============
; Create a random graph with some given number n of vertices, and m edges, to guarantee
; that the graph is connected.
; Assume  m >= n-1   and m <= n(n-1)/2
; Place vertices in random locations.  Edges should be randomly selected... but to guarantee
; connectivity.
to random-graph [ n m ]
   setup

  ; Error checking for values of n and m.
  ; Make sure there is at least 1 vertex.
  if n <= 0 [
    write (word "Can't create a graph without vertices.  Setting n = 1")
    set n 1
  ]

  ; Ensure a correct relationship between n and m:  n-1 <= m <= n(n-1)/2
  if m > n * (n - 1) / 2  [
    write (word "Can't create a graph with " m " edges and " n " vertices.  Adjusting m...")
    set m ( n * (n - 1) ) / 2
  ]
  if m < n - 1 [
    write (word "Need " (n - 1) " edges to make a connected graph. Adjusting m...")
    set m n - 1
  ]

  ; Create the vertices and then the edges.
  make-vertex-set n
  make-edge-set n m
  apply-weight-function

  ; The following may help spread out vertices resulting in easier-to-see edges
  ; it will leave turtle 0 at the origin
  ask turtle 0 [setxy 0 0 ]
  repeat 1000 [ layout-spring vertices with [who != 0] links .8 15 2  ]

  ; The longest possible path has n-1 edges and so it's weight is at most (n-1) * max-edge-weight
  ; The following value will be larger than any existing shortest path in the graph.
  set infinity 1 + (n - 1) * max-edge-weight
end

; Creates n vertices in random locations, and labels by their who (ID)
to make-vertex-set [ n ]
  create-vertices n [
    set shape "circle"
    set size .5
    set color black
    set label-color red
    if show-vertex-labels? [set label (word who "    " )]
    setxy random-xcor random-ycor
  ]
end

; Adds m edges between the existing n vertices
; guarantees a connected graph
; assume that n-1 <= m <= n(n-1)/2
to make-edge-set [ n m ]
  ; ensure that the first n-1 edges connect the graph
  ask one-of vertices [ create-link-with one-of other vertices ]           ; start with one edge
  repeat (n - 2) [           ; each iteration, add one edge that doesn't form a cycle
    ask one-of vertices with [any? my-links ][
      create-link-with one-of vertices with [not any? my-links]
    ]
  ]

  ; add the remaining edges randomly.
  repeat ( m - (n - 1)) [
    ask one-of vertices with [count my-links < (n - 1)][
      create-link-with one-of other vertices with [not link-neighbor? myself]
    ]
  ]
end

to apply-weight-function
  ask links [
    set weight 1 + random max-edge-weight
    set label weight
    set label-color black
  ]
end

to load-file [ file-name ]
  setup
  file-close-all
  ask vertices [ die ]

  file-open file-name
  let num-v file-read
  let num-e file-read
  print (word "Creating a file with " num-v " vertices and " num-e " edges.")
  repeat num-v [
    create-vertices 1 [
      set xcor file-read
      set ycor file-read
      set name file-read
      set shape "circle"
      set size .5
      set color black
      set label-color red
      if show-vertex-labels? [set label name]
    ]
  ]
  repeat num-e [
    let s file-read
    let d file-read
    let wt file-read
    ask vertex s [
      create-link-with vertex d [
         set weight wt
         set label weight
         set label-color black
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
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
12
10
121
44
make-graph
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
13
94
186
127
num-vertices
num-vertices
1
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
13
131
186
164
num-edges
num-edges
1
200
14.0
1
1
NIL
HORIZONTAL

BUTTON
13
47
120
81
NIL
reset-graph
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
247
163
282
Agent-Based SSSP
if search-root < count vertices [\nagent-sssp turtle search-root\n]
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
12
169
205
202
visualize-SSSP-tree?
visualize-SSSP-tree?
0
1
-1000

SWITCH
12
207
207
240
show-vertex-labels?
show-vertex-labels?
0
1
-1000

INPUTBOX
24
327
174
387
search-root
2.0
1
0
Number

BUTTON
23
287
133
321
Dijkstra SSSP
d-sssp vertex search-root
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
129
11
195
44
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

INPUTBOX
26
397
202
457
graph-file-name
simple-graph.txt
1
0
String

BUTTON
129
52
208
85
load graph
load-file graph-file-name
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
NetLogo 6.2.1
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
