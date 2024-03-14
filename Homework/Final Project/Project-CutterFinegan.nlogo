; FINAL PROJECT: Evacuation Plans in Schools

; PARTNERS: Kaela Finegan and Caroline Cutter


; Code modified from Professor Dickersons sample codes
;    - distance to islands - used for distance to doors and distance to exits




; ========================================= VARIABLES =====================================================


; Includes and extensions

__includes [ "heap.nls" ]

extensions [sound]


; Breeds

breed [ people person ]

breed [ fires fire ]





; Instance Variables
people-own [
  chaos-level  ; chaos level / personality of the people
  speed        ; speed at which they move
  trapped?     ; are they trapped in the building?
]

patches-own [
  class         ; the different class of the patches (room, wall, exit, door, outside, on-fire)

  dist-to-exit  ; the distance to the exit from that patch
  closest-exit  ; the patch number of the closest exit
  queued?       ; has this patch been queued? ( updated the distance to the exit and closest exit )
  index-in-pq   ; index in the queue
  visited?      ; has this patch been visited / updated
]



; Globals

globals [

  people-saved-ct     ; the number of people who have been saved
  people-trapped-ct   ; the number of people who are trapped in the building

  wall      ; is this patch a wall?
  exit      ; is this patch an exit?
  doorway   ; is this patch a doorway?
  room      ; is this patch a room?
  outside   ; is this patch outside?
  on-fire   ; is this patch on fire?

  fire-xcor ; xcor of the fire (only if user is choosing fire)
  fire-ycor ; ycor of the fire (only if user is choosing fire)
]

; Globals on Interface

     ; num-people ............ number of people in the building
     ; emergency-type ........ fire drill or real fire
     ; visualize-setup ....... if you want to see the setup or not
     ; size-fire ............. size of the fire you want - has grey smoke surrounding it which people will also avoid
     ; random-fire? .......... is this a randomly generated fire or a predetermined one?
     ; filename .............. filename of imported floorplan
     ; total-chaos-level ..... what percent of each type of person is there? (overall chaos level)





; ================================================= SETUP PROCEDURES ==================================================


; Observer Context
; setup our world including the globals, the world, the people and the fire
to setup
  ca
  reset-ticks

  init-globals
  init-world

  ; check if the emergency type is a real fire. If so, make a fire
  if emergency-type = "real-fire" [
     make-fire
  ]

  ; update all distances to exit and closest exits for each patch
  distance-to-exit

  init-people


   ; check if people are trapped
  set people-trapped-ct count people with [ trapped? = true ]

  ; play fire alarm
  sound:play-sound "firealarm.wav"



end




; Observer Context
; initialize our globals
to init-globals

  ; intialize the counters
  set people-saved-ct 0
  set people-trapped-ct 0

  ; create numbers for the classes of patches for efficiency
  set wall 1
  set exit 2
  set doorway 3
  set room 4
  set outside 5
  set on-fire 6

end








; Observer Context
; create our world based on the floorplan
to init-world

  ; import picture and reset world/patch size
  if filename = "forrest.jpeg" [ resize-world 0 440 0 252 set-patch-size 1.75 ]
  if filename = "bihall.jpeg" [ resize-world 0  391 0 254 set-patch-size 1.85 ]

  import-pcolors filename

  ask patches [

    ; Initialize variables
    set dist-to-exit 10000
    set visited? false
    set closest-exit -1

    ; Initialize classes of patches based off color
    if pcolor mod 10 < .1 or pcolor < 9.9 [ set pcolor black set class wall  set dist-to-exit 10000]  ; black

    if pcolor mod 10 >= 9.8 and pcolor mod 10 < 10 [ set pcolor white set class room ]

    if shade-of? pcolor green [ set pcolor green set class outside set dist-to-exit -1]

    if shade-of? pcolor blue [ set pcolor blue set class doorway ]

    if shade-of? pcolor red [ set pcolor red set class exit ]
  ]

end




; Observer Context
; initialize our people
to init-people

  ; create people
  create-people num-people [
    move-to one-of patches with [ class = room ] with [ not any? turtles-here ]
    set size 5
    set shape "person"

    decide-chaos-level
    chaos-characteristics

    ; if its a real fire, move people so they are not on patches that are on fire
    if emergency-type = "real-fire" [
      move-to one-of patches with [class = room] with [ not any? turtles-here] with [ distance one-of fires > size-fire + 2 ]
    ]

    ; check if they're trapped
    if [dist-to-exit] of patch-here = 4  * world-height [
      set trapped? true
    ]
  ]
end





; Decides the chaos of people based off the total-chaos-level (high, normal, low)
to decide-chaos-level

  let chance random-float 1

  if total-chaos-level = "low" [                            ; LOW CHAOS
    if chance <= .5 [ set chaos-level 1 ]                      ; 50% chance patient
    if chance > .5 and chance <= .8 [ set chaos-level 2 ]      ; 30% chance worried
    if chance > .8 [ set chaos-level 3 ]                       ; 20% chance chaotic
  ]

  if total-chaos-level = "normal" [                         ; NORMAL CHAOS
    set chaos-level (random 3) + 1                             ; 33.33% chance for each type of person
  ]

  if total-chaos-level = "high" [                            ;  HIGH CHAOS
    if chance <= .5 [ set chaos-level 3 ]                      ; 50% chance chaotic
    if chance > .5 and chance <= .8 [ set chaos-level 2 ]      ; 30% chance worried
    if chance > .8 [ set chaos-level 1 ]                       ; 20% chance patient
  ]



end



; Turtle Context
; helper function to init-people, sets personalities based off chaos levels
to chaos-characteristics

  ; patient
  if chaos-level = 1 [ set speed 3 set color yellow]

  ; worried
  if chaos-level = 2 [ set speed 3 set color orange]

  ; chaotic
  if chaos-level = 3 [ set speed 5 set color red ]

end




; Observer Context
; helper function to make a fire
to make-fire
  create-fires 1 [
    ; if this is a random fire
    ifelse random-fire? [
      move-to one-of patches with [ class = room ]
    ][
     ; Else - have user choose location of fire with mouse
      user-message "Click your mouse on where you would like the fire to be."

      ; allow the user to choose a location for the fire with their mouse
      let fire-set? false
      while [ not fire-set? ] [
        if mouse-down?  [ set fire-xcor mouse-xcor set fire-ycor mouse-ycor set fire-set? true]
      ]
      if [class] of patch fire-xcor fire-ycor = outside [
        ; the fire chosen location is outside
        user-message "Fire outside the building. If you want it inside, please press halt and try again!"
      ]
  ]
    ; create the fire
    if not random-fire? [ setxy fire-xcor fire-ycor ]
    set size size-fire
    set shape "fire"
    set color red
    ; initialize the smoke radius
    ask patches in-radius size-fire [
      set pcolor grey
      set class on-fire
      set dist-to-exit 10000
    ]
  ]
end




; Observer Context
; This will grow the fire and smoke ring by radius 5 and reassess evacuation plans
to grow-fire
  ask one-of fires [
    set size size + 1
    ask patches in-radius ([size] of self) [
      set pcolor grey
      set class on-fire
      set dist-to-exit 10000
    ]
  ]
   ; update the distances to exit
   distance-to-exit

end















; ================================================= DISTANCE TO EXITS  ==================================================

; Observer Context
; The code was used modified Matthew Dickersons "distance-to-island" function in Alaska Mapping
; This function is a modified BFS and Dijkstra's SSSP
; This utilizes a min-heap and priority queue to efficiently find the distance to the closest exit
;    by storing closest distance in each patch. Euclidean distance is not used because people must avoid
;    running into walls. Each item in the queue is searched until there are no patches/paths left to search
to distance-to-exit

  let pq new-pqueue [ [p1 p2] -> [dist-to-exit] of p1 < [dist-to-exit] of p2 ] [ [p i] -> ask p [set index-in-pq i]]

  ; initialization
  let room-patches patches with [class = room or class = doorway]                  ; Initialize room-patches which stores all patches that are rooms or doorways
  ask patches [
    ; on a room or doorway patch
    if class = room or class = doorway [                                           ; Sets all room-patches to have a max dist-to-exit and closest-exit
      set dist-to-exit 4 * world-height
      set closest-exit patch max-pxcor max-pycor
      set queued? false
    ]
    ; on exit patch
    if class = exit and not any? patches with [class = on-fire] in-radius 6 [     ; Sets alll exit patches to have dist 0, closest exit self and inserts them into the Priority Queue
      set dist-to-exit 0
      set pq insert pq self
      set queued? true
      set closest-exit self
    ]
  ]

  ; Process every room, doorway, and exit patch
  while [not is-empty? pq] [                                           ; Remove first item in priority queue and processes it
    let front report-min pq
    set pq delete-min pq
    ask front [

      if (class = room or class = doorway) and visited? = false [      ; This patch is now visited and complete with shortest dist-to-exit and closest-exit
        if visualize-setup? = true [set pcolor red ]
        set visited? true
      ]

      ; Check the neighbors that are not yet finalized, and update them. Add them to the queue (if needed) or decrease their key
      ask neighbors with [(class = room or class = doorway) and dist-to-exit > [dist-to-exit] of myself] [
        if not queued? [
          set pq insert pq self                                        ; Inserts room/door neighbors with larger distance into priority queue to be processed
          set queued? true
        ]

        if [dist-to-exit] of myself + 1 < dist-to-exit [               ; Updates distance of neighbor if the distance (+ 1 patch) is smaller
          set closest-exit [closest-exit] of myself
          set dist-to-exit [dist-to-exit] of myself + 1
          set pq decrease-key pq index-in-pq
        ]                                                              ; Repeat loop until all room-patches are processed and priority queue is empty
      ]
    ]
  ]
  ; VISUALIZE AND SCALE COLOR THE DISTANCE TO THE EXIT
  let max-d [dist-to-exit] of max-one-of room-patches [dist-to-exit]
  ask patches with [ class = doorway ] [ set pcolor blue ]
  if visualize-setup? = true [ask patches with [class = room ] [ set pcolor scale-color blue dist-to-exit  (1.25 * max-d) ( 0 - .25 * max-d )]]
end






; ============================================== MAIN MOVEMENT  & GO PROCEDURES ==============================================


; Observer Context
; Moves people once based off their chaos level
to go-once
 ; different go functions for each chaos level
 ask people [
    if chaos-level = 0 [ go-zero ]

    if chaos-level = 1 [ go-one ]

    if chaos-level = 2 [ go-two ]

    if chaos-level = 3 [ go-three ]
  ]

  tick
end



; Observer Context
; Moves people based off chaos level until all people are saved or trapped
;   a message is broadcasted at the end of the function which displays the time and counters
to go-forever

  while [(people-trapped-ct + people-saved-ct) < num-people] [

     ; different go functions for each chaos level
     ask people [
        if chaos-level = 0 [ go-zero ]

        if chaos-level = 1 [ go-one ]

        if chaos-level = 2 [ go-two ]

        if chaos-level = 3 [ go-three ]
      ]

  tick
  ]

  ; DISPLAY MESSAGE with time and counters
  ;  model finished running - tell user the results
  let minutes floor (ticks / 60 )
  let seconds ticks mod 60
  wait .5

  user-message (word "It took " minutes "  minutes and " seconds " second(s).                    "
     "                             People Saved: " people-saved-ct " People Trapped: " people-trapped-ct)


end







; ---------------------------  GO HELPER FUNCTIONS - Chaos Levels ---------------------------
;                                   ( all in turtle context)

; Chaos level 0 - outside
; just move around outside of building
to go-zero
  fd 8
  ; update the count of people saved
  set people-saved-ct people-saved-ct + 1
  ; let them die now that safely out of building
  die
end



; Chaos level 1 - patient
; Only move if nobody is in front of them
to go-one


  repeat speed [
     ; check if already outside and safe
     check-if-saved
     ; change to chaos level 2 if within close range of an exi
     if any? patches with [ class = exit ] in-radius 10 [  set chaos-level 2]
     ; find next patch
     let patch-move-to find-best-patch
     ; move to next patch if no one is there
     if not any? people-on patch-move-to [ move-to patch-move-to]
     ; check again if saved
     check-if-saved
  ]
end



; Chaos Level 2 - worried
; Go around if someone is in front of them, and go forward if nobody is in front of them
to go-two

  repeat speed [
   ; find next patch to go to
   let patch-move-to find-best-patch

   face patch-move-to

   ifelse any? people-on patch-ahead 1
     [ go-around ]  ; someone is in front of them, go around them
     [  move-to patch-move-to ] ; no one in front of them, go to next patch

    ]
  ; check if saved
  check-if-saved

end




; Chaos Level 3 - chaotic
;  "Push" people out of the way if there is someone in front of them
to go-three

  repeat speed [
    ; set next patch to go to
    let patch-move-to find-best-patch

    face patch-move-to
    ; if someone is in front of them, push them out of the way
    if any? people-on patch-ahead 1 [ push ]
    ; move to next patch
    move-to patch-move-to

    ]
  ; check if saved
  check-if-saved

end







; ---------------------------  CHAOS LEVELS - Helper Functions  ---------------------------
;                                   ( all in turtle context)




; Reports the patch to the exit
to-report find-best-patch

  ; set best-patch to patch-here (gets updated in next line)
  let best-patch patch-here

  ; finds patch of neighbor with smallest distance to exit
   ask patch-here [
      set best-patch min-one-of neighbors [dist-to-exit]
    ]
   ; report our new patch to go to
   report best-patch
end





; Checks if person is out of building, if so resets their chaos level to 0 (outside)
to check-if-saved
  ; if on the exit or a limb is on the wall near the exit, go outside
  if [class] of patch-here = exit or ([class] of patch-here = wall and any? patches with [ class = exit ] in-radius 1 ) [
    face one-of patches with [ class = outside ] in-radius 3
    fd 2
  ]
  ; if you are now outside, reset your chaos level to 0
  if [class] of patch-here = outside [
     fd 2
     set chaos-level 0
    ]
end





; Go around another person (helper for go-two)
to go-around
  let head heading

  ; turn to the side (making sure not facing a wall)
  rt 90
  if [class] of patch-ahead 1 = wall [ rt 180 ]

  ; go forward one
  fd 1

  ; face original heading and move past the person
  set heading head
  fd 3

end






; "Pushes" someone out of the way by moving them to the side (helper for go-three)
to push

    let best-path patch-ahead 1

    let head heading

    ; ask the people on the patch you want to go to
    ask people-on best-path [

      ; turn to the side (making sure not facing a wall)
      rt 90
      if [class] of patch-ahead 1 = wall [ rt 180 ]

     ; Move fd out of the way, then face original heading
      fd 2
      set heading head
    ]

end














; ==============================================  SCRAPBOOK  ==============================================

;              We included some of our old code to show how we increased efficiency and
;              attempted to make our program more life-like. All of the code below is
;              commented out, so none of it is functional to the program.






;to find-rooms
;  set room-ct 0                                                                          ; initialize the island count and the patches so that there are no islands yet.
;  ask patches [set room-number 0]
;  while [ any? patches with [ room-number = 0 and class = room ]][                            ; pick a patch that is not yet part of an island and find its island
;    make-room (one-of patches with [ room-number = 0 and class = room ])
;  ]
;end
;
;; Start with patch p and make an island by growing out in all directions. This is done with a queue. We start with p in the queue.
;; When a vertex is removed from the queue, all its unlabeled land neighbors are labeled and added to the queue. When no more adjacent
;; unlabeled land neighbors can be found, the island is complete.
;to make-room [ p ]
;  set room-ct room-ct + 1                 ; start a new island. it will have at least one patch
;
;  ; For more variety of colors (since the default netlogo color space has only 14 colors) we use the RGB color space. This means we can't scale color.
;  ; Create a random RGB color
;  let r random 256
;  let g random 256
;  let b random 256
;  let island-clr (list r g b)
;
;  ; Initialize a queue that will process all vertices in this island, starting with p
;  let q (list p )
;  ask p [set room-number room-ct]                                                  ; Add this patch to the island and color it
;
;  ; Process the queue.  Remove a patch, mark any unlabeled landneighbors as part of the same island, and then label them
;  while [ length q > 0 ][
;    let next first q                                                               ; Dequeue the patch
;    set q but-first q
;    ask next [
;      ;set pcolor island-clr
;      ask neighbors with [ room-number = 0 and class = room ][        ; Process its neighbors
;         set room-number room-ct
;         set q lput self q
;     ]
;    ]
;  ]
;end
;
;
;
;
;
;
;
;
;;; Find Doorways --- Taken from professor dickersons code (lab 10)
;
;
;
;to find-doors
;  set door-ct 0                                                                          ; initialize the island count and the patches so that there are no islands yet.
;  ask patches [set door-number 0]
;  while [ any? patches with [ door-number = 0 and (class = doorway or class = exit)]][                            ; pick a patch that is not yet part of an island and find its island
;    make-door (one-of patches with [ door-number = 0 and (class = doorway or class = exit) ])
;  ]
;end
;
;
;
;
;to make-door [ p ]
;  set door-ct door-ct + 1                 ; start a new island. it will have at least one patch
;
;
;  ; Initialize a queue that will process all vertices in this island, starting with p
;  let q (list p )
;  ask p [set door-number door-ct]                                                  ; Add this patch to the island and color it
;
;  ; Process the queue.  Remove a patch, mark any unlabeled landneighbors as part of the same island, and then label them
;  while [ length q > 0 ][
;    let next first q                                                               ; Dequeue the patch
;    set q but-first q
;    ask next [
;      ask neighbors with [ door-number = 0 and (class = doorway or class = exit) ][        ; Process its neighbors
;         set door-number door-ct
;         set q lput self q
;     ]
;    ]
;  ]
;end
;
;
;
;
;
;
;
;
;









; ---------------------------------------------- Graph Functions -------------------------

;
;
;; Create graph that shows paths to exits
;to create-graph
;
;  ; Put vertex at each doorway
;
;   ;THIS ONLY WORKS AFTER MAKE-DOOR FUNCTION
;  let i 1
;  repeat door-ct[
;
;    let x 0
;    let y 0
;
;    ask one-of patches with [ door-number = i ] [ set x pxcor set y pycor ]
;
;
;    create-vertices 1 [
;      setxy x y
;      set shape "circle"
;      set size 5
;      set color yellow
;
;    ]
;
;    set i i + 1
;
;  ]
;
;
;
;
;  ; PUTS VERTEX IN CENTER OF EACH ROOM
;
;  let i2 1
;
;
;  ; So we can find max and min
;
;  repeat room-ct [
;
;    let x-max 0
;    let x-min world-width
;    let y-max 0
;    let y-min world-height
;
;    ask patches with [ room-number = i2 ]  [
;
;      if pxcor > x-max [ set x-max pxcor ]
;      if pxcor < x-min [ set x-min pxcor ]
;      if pycor > y-max [ set y-max pycor ]
;      if pycor < y-min [ set y-min pycor ]
;
;    ]
;
;    create-vertices 1 [
;      setxy ( ( x-max + x-min ) / 2)  ( ( y-max + y-min ) / 2)
;      set shape "circle"
;      set size 5
;      set color yellow
;
;    ]
;
;    set i2 i2 + 1
;
;
;  ]
;
;
;
;
;
;
;
;
;end
;
;
;
;to reset-graph
;
;end
;






; Accomplishes the same task as the previous two procedures, but much more efficiently.
; This approach is more complex to understand and encode, but instead of time O(n*c) it requires time O(n log n)
; This version uses a priority queue with a decrease-key operation, much like the Dijkstra SSSP algprithm.
; The priorityqueue is initalized with coastal patches with themselves as the nearest coast, and a distance of 0.
;  Every time a patch p is removed from the queue, it will have a nearest coast patch (say c).
; Its unvisited neighboring water patches are looked at, and their distance to c is measured. If that unvisited
; neighbor has not been put in the queue, it is added to the queue with c as a candidate for the nearest coast.
; If the neighbor is already in the queue, then if c is closer than its previous best candidate, it is nearest
; coast is updated, and its gets moved forward in the priority queue with a decrease key operation.
;to distance-to-exit
;
;  ; create a priority queue with decrease-key operation. This require each patch to know where it is in the queue
;  ; The first parameter is a comparison reporter for patches based on their (currently best known) distance to the coast.
;  ; The second parameter is a first order procedure that tells how to update patch p with a new location in the queue
;  let pq new-pqueue [ [p1 p2] -> [dist-to-exit] of p1 < [dist-to-exit] of p2 ] [ [p i] -> ask p [set index-in-pq i]]
;
;  ; initialization
;
;  let room-patches patches with [class = room ]
;  ask patches [
;    if class = room [
;      set dist-to-exit world-height
;      set closest-exit patch max-pxcor max-pycor
;      set queued? false
;      ; set pcolor yellow
;    ]
;    if class = exit [
;      set dist-to-exit 0
;      set pq insert pq self
;      set queued? true
;      set closest-exit self
;      ; set pcolor pink
;    ]
;  ]
;
;
;  ; Process every single coast and water patch.
;  while [not is-empty? pq] [
;    let front report-min pq                                ; Remove front item from priority queue for processing
;    set pq delete-min pq
;    ask front [                                            ; This patch now has its final values for closest-coast and dist-to-coast
;      if visualize-setup? = true [if class = room and visited? = false [set pcolor red set visited? true]  ]                  ; Only used for visualization
;
;      ; Check the neighbors that are not yet finalized, and update them. Add them to the queue (if needed) or decrease their key
;      ask neighbors with [class = room and dist-to-exit > [dist-to-exit] of myself] [
;        if not queued? [
;          set pq insert pq self
;          set queued? true
;        ]
;;        if distance [closest-exit] of myself < dist-to-exit [
;;          set closest-exit [closest-exit] of myself
;;          set dist-to-exit (distance closest-exit)
;;          set pq decrease-key pq index-in-pq
;;        ]
;
;        if [dist-to-exit] of myself + 1 < dist-to-exit [
;          set closest-exit [closest-exit] of myself
;          set dist-to-exit [dist-to-exit] of myself + 1
;          set pq decrease-key pq index-in-pq
;        ]
;
;      ]
;      ; this will overwrite the distance to the exit of the doorway several times, but that is okay
;      ask neighbors4 [ if class = doorway [
;        let dnum door-number
;        ; this is the closest distance to exit from the doorway
;        let distance1 [dist-to-exit] of myself
;        ask patches with [ door-number = dnum] [set dist-to-exit distance1 ]]
;      ]
;    ]
;  ]
;
;  let max-d [dist-to-exit] of max-one-of room-patches [dist-to-exit]
;  ;ask room-patches [ set pcolor scale-color blue dist-to-exit  (1.25 * max-d) ( 0 - .25 * max-d )]
;end



;------------------------------------ SAME THING FOR DOORS -------------------------------------------------



;to distance-to-door
;
;
;  ; create a priority queue with decrease-key operation. This require each patch to know where it is in the queue
;  ; The first parameter is a comparison reporter for patches based on their (currently best known) distance to the coast.
;  ; The second parameter is a first order procedure that tells how to update patch p with a new location in the queue
;  let pq new-pqueue [ [p1 p2] -> [dist-to-door] of p1 < [dist-to-door] of p2 ] [ [p i] -> ask p [set index-in-pq i]]
;
;  ; initialization
;
;  let room-patches patches with [class = room and visited? = false]
;  ask patches [
;    if class = room and visited? = false [
;      set dist-to-door world-height
;      set closest-door patch max-pxcor max-pycor
;      set queued? false
;
;    ]
;    if class = doorway [
;      set dist-to-door 0
;      set pq insert pq self
;      set queued? true
;      set closest-door self
;
;    ]
;  ]
;
;
;  ; Process every single coast and water patch.
;  while [not is-empty? pq] [
;    let front report-min pq                                ; Remove front item from priority queue for processing
;    set pq delete-min pq
;    ask front [                                            ; This patch now has its final values for closest-coast and dist-to-coast
;      if visualize-setup? = true [ if class = room and visited? = false [set pcolor red set visited? true]  ]                  ; Only used for visualization     ; right here
;
;      ; Check the neighbors that are not yet finalized, and update them. Add them to the queue (if needed) or decrease their key
;      ask neighbors with [class = room and dist-to-door > [dist-to-door] of myself and visited? = false] [
;        if not queued? [
;          set pq insert pq self
;          set queued? true
;        ]
;;        if distance [closest-door] of myself < dist-to-door [        ; MYSELF IS FRONT , SELF IS NEIGHBOR
;;          set closest-door [closest-door] of myself
;;          set dist-to-door (distance closest-door)
;;          set dist-to-exit (dist-to-door  + [dist-to-exit] of closest-door)
;;          set pq decrease-key pq index-in-pq
;
;       if [dist-to-door] of myself + 1 < dist-to-door [
;          set closest-door [closest-door] of myself
;          set dist-to-door [dist-to-door] of myself + 1
;          set dist-to-exit (dist-to-door  + [dist-to-exit] of closest-door)
;         set pq decrease-key pq index-in-pq
;
;
;
;
;        ]
;      ]
;    ]
;  ]
;
;  ; this is recoloring all the patches that are rooms, not just the ones we found distances to in this function
;  ; so including rooms that were found in the distance-to-exit function
;  let max-d [dist-to-exit] of max-one-of patches with [ class = room ] [dist-to-exit]
;  if visualize-setup? = true [ ask patches with [ class = room ] [ set pcolor scale-color blue dist-to-exit  (1.25 * max-d) ( 0 - .25 * max-d )] ]
;end
;




; --------------------------- Go helper functions - Chaos levels  ---------------------


;; Chaos level 0
;; just move around outside of building
;to go-zero
;  fd 8
;  set people-saved-ct people-saved-ct + 1
;  die
;end
;
;
;
;
;; Chaos level 1
;; Only move if nobody is in front of them
;to go-one
;
;
;  check-if-saved
;  if any? patches with [ class = exit ] in-radius 10 [ set chaos-level 2]
;
;  let patch-move-to find-best-patch
;
;
;  ask patch-move-to [
;    if  (count people in-radius 4 <= 1) [ ask myself [ move-to patch-move-to]]
;  ]
;
;; if not ([any? other people in-radius 2] of patch-move-to ) [ move-to patch-move-to]
;
;    check-if-saved
;
;
;end
;
;
;
;; Chaos Level 2
;; Go around if someone is in front of them, and go forward if nobody is in front of them
;to go-two
;
;  repeat speed [
;
;      let patch-move-to find-best-patch
;
;      face patch-move-to
;
;
;
;  ask patch-move-to [
;    ifelse  (count people in-radius 4 > 1)
;      [ ask myself [ go-around ] ]
;      [ ask myself [ move-to patch-move-to]]
;    ]
;  ]
;
;
;  check-if-saved
;
;
;
;end
;
;
;
;
;; Chaos Level 3
;;  "Push" people out of the way if there is someone in front of them
;to go-three
;
;  repeat speed [
;
;      let patch-move-to find-best-patch
;
;      face patch-move-to
;
;       if ( count people in-radius 4 > 1) [ push ]
;
;       move-to patch-move-to
;
;    ]
;
;  check-if-saved
;
;end
;
;
;
;
;
;
;; --------------------------- Chaos helper functions   ---------------------
;
;
;
;
;
;; Reports the best path to exit
;to-report find-best-patch
;
;  let best-patch patch-ahead 1
;
;
;
;   ask patch-here [
;
;      ask neighbors [
;          if dist-to-exit < [dist-to-exit] of best-patch and ( class != wall) [ set best-patch self]
;      ]
;    ]
;     report best-patch
;end
;
;
;
;
;
;; Checks if person is out of building, increases saved count
;to check-if-saved
;
;  if [class] of patch-here = exit or ([class] of patch-here = wall and any? patches with [ class = exit ] in-radius 1 ) [
;    face one-of patches with [ class = outside ] in-radius 3
;    fd 2
;  ]
;
;  if [class] of patch-here = outside [
;     fd 2
;     set chaos-level 0
;     ;die
;    ]
;end
;
;
;
;
;
;
;
;
;; Go around another person (helper for go-two)
;to go-around
;  let head heading
;
;  rt 90
;  if [class] of patch-ahead 1 = wall [ rt 180 ]
;
;  fd 1
;  set heading head
;  fd 3
;
;
;end
;
;
;
;
;
;
;; "Pushes" someone out of the way by moving them to the side 9helper for go-three
;to push
;
;    let best-path patch-ahead 1
;
;    let head heading
;
;    let chaotic-person self
;
;  ask best-path [
;    ask people in-radius 4 [
;      if self !=  chaotic-person [
;        rt 90
;
;        if [class] of patch-ahead 1 = wall [ rt 180 ]
;
;        fd 1
;
;        set heading head
;
;      ]
;    ]
;  ]
;
;
;
;
;end
;
@#$#@#$#@
GRAPHICS-WINDOW
250
10
1029
461
-1
-1
1.75
1
10
1
1
1
0
0
0
1
0
440
0
252
0
0
1
ticks
30.0

BUTTON
87
379
153
412
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
34
247
206
280
num-people
num-people
1
150
103.0
1
1
NIL
HORIZONTAL

BUTTON
30
429
111
462
go once
go-once
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
257
611
351
656
People Saved
people-saved-ct
17
1
11

SWITCH
42
309
199
342
visualize-setup?
visualize-setup?
0
1
-1000

CHOOSER
47
120
186
165
emergency-type
emergency-type
"firedrill" "real-fire"
0

SLIDER
1055
147
1227
180
size-fire
size-fire
5
100
20.0
1
1
NIL
HORIZONTAL

SWITCH
1068
94
1207
127
random-fire?
random-fire?
1
1
-1000

MONITOR
306
550
422
595
Seconds Elapsed
ticks
17
1
11

MONITOR
379
610
483
655
People Trapped
people-trapped-ct
17
1
11

BUTTON
123
427
219
460
go forever
go-forever
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
48
57
186
102
filename
filename
"forrest.jpeg" "bihall.jpeg"
0

PLOT
530
503
750
664
People In Building
Time (Ticks)
People
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Chaotic " 1.0 0 -2674135 true "" "plot (count people with [color = red ])"
"Worried" 1.0 0 -955883 true "" "plot count people with [ color = orange ] "
"Patient" 1.0 0 -1184463 true "" "plot count people with [ color = yellow ] "

PLOT
784
502
984
669
% People Saved
Time (Ticks)
People Saved 
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (people-saved-ct / num-people ) * 100"

TEXTBOX
1061
50
1211
68
Fire Characteristics: 
14
0.0
1

TEXTBOX
341
510
402
528
DATA: 
14
0.0
1

TEXTBOX
89
23
239
41
SETUP: 
14
0.0
1

BUTTON
1091
225
1181
258
NIL
grow-fire
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
48
183
186
228
total-chaos-level
total-chaos-level
"low" "normal" "high"
1

@#$#@#$#@
Kaela Finegan and Caroline Cutter

## WHAT IS IT?

The purpose of this program is to model evacuation plans of buildings,  to find the best routes to exits, and to find which types of behaviors are most effective in emergency situations. This is a simplified model of a fire drill or an emergency evacuation plan of a building. It efficiently finds the nearest exit from anywhere in the building. This model uses a residential building (Forrest Hall) and an academic building (McCardell Bicentennial Hall) from the Middlebury College campus. However, the program is versatile and can be used for multiple different buildings provided the floorplans are properly colored (walls are black, floors are white, doorways are blue, exits are red and outside the building is green). There are three different chaos level possibilities for each person. The user can adjust the proportion of people with each choas level to see which assignment of chaos levels works best in an emergency. This program can be a fire drill, where the fastest way to each exit is modeled (a simple evacuation), or a real fire, where the fastest exit avoiding the fire is modeled. The user can also change the characteristics of the fire, such as location and size. Plots and monitors aid the users ability to see how many people are saved/trapped, how long the evacuation took and how fast people of different chaos levels were able to exit the building. 




## HOW IT WORKS



**1. SETUP**

  * The user can determine which floorplan they want to use, either Forrest Hall or McCardell Bicentennial Hall from Middlebury College
  * The user can determine the number of people in the building 
  * The user can determine whether it is a fire drill or a real fire
  * The user can determine if they want to visualize the setup - this will scale shade the building's patches blue so the darker patches are further from the exit and the lighter ones are closer.
  * **A Real Fire:**
    * A fire is represented by a turtle and is surrounded by a "smoke" ring which is colored grey 
    * The best path is determined so that the fire is avoided. If the fire is blocking a path to the closest exit, the person will follow a different path to find another exit.
    * If the user chooses to mimic a real fire, they have the option to create a randomly-located fire or choose their own coordinates by using your mouse to click the desired location
    *  The size of the fire can be adjusted initially, but the fire can also grow during the simulation with the "grow-fire" button. This button increases the size of the fire and the smoke ring by a 5 patch radius. The best route will be redetermined if the fire grows, just in case the best path is affected.


**2. SHORTEST PATH AND MOVEMENT OF PEOPLE**
 
  * The shortest path to each exit is determined using a mix of a breadth-first search, Dijkstra's SSSP algorithm and a priority queue (procedure modified was code used from Matthew Dickerson's sample code)
  * Each path has the instance variables dist-to-exit and closest-exit, which are used to determine the shortest path to their exits. 
  * The search begins from each exit, and expands similar to a breadth-first search, updating each patch's instance variables until all paths are reached. 
  * A breadth-first search was used because instead of direct distance to the exit, the program needed to use the distance of patches (similar to Dijkstra's), since people can't walk through walls. 
  * People determine which patch to move to by finding the neighboring patch with the shortest distance to an exit. 
  * Once they leave the building, they are saved. However, if there is a fire people can be trapped in the building. 

**3. CHAOS-LEVELS**
 
  * There are four different chaos-levels for people that determines how they behave:
    * Level 0: Outside, this person is saved and the saved count will be updated. They will move forward outside and then disappear.
    * Level 1: Patient (yellow) - this person will move forward at a normal pace but will patiently wait if there is someone in front of them. When the patient people are close to the exit, they will increase their chaos to level 2 in order to get out of the building.
    * Level 2: Worried (orange) - this person will move forward at a normal pace but will move around someone in front of them.
    * Level 3: Chaotic (red) - this person will move at a faster pace, but push people in front of them out of the way (they can even push people into the smoke).
  * The user can control the total chaos levels with a chooser on the interface with three different options (based on probabilities) 
    * Low Chaos: 50% level 1, 30% level 20% level 3
    * Normal Chaos: 33.3% Levels 1, 2 or 3
    * High Chaos: 50% level 3, 30% level 20% level 1

**4. DATA: Monitors and Plots**
 
  * We included monitors and plots to help the user visualize what is happening, which methods are most effective, and the difference between behaviors.
  * Once the fire drill is finished the program will report how long the drill took, how many people were saved and how many people were trapped.
  * **Monitors**
    * Seconds Elapsed - this counter shows the seconds elapsed since the fire drill first started. 
    *  People Saved - a count of how many people escaped the building and were saved
    * People Trapped - a count of how many people were not able to escape the building and are trapped by the fire
  * **Plots** 
    * People in the building based on chaotic-behavior: this graph makes it easy to see which behavior gets out of the building fastest.
    * % of People saved over time: this shows the percent of the population that is saved over time, so it is easy to compare which types of behavior finishes the drill the fastest.



## HOW TO USE IT


**STEPS:**

1. Choose floorplan (either Forrest Hall or BiHall)
2. Choose chaos-level (high, normal, low)
3. Choose the number of people in the building
4. Choose emergency-type ( fire drill or real fire)
**skip to step 7 if you chose fire-drill**
5. Choose fire size
6. Choose if you want a random fire, if you don't, choose the coordinates of the fire by clicking on the desired location with your mouse when prompted (if the fire is outside the building, it will allow you to choose a different location for the fire or it can be outside the building)
7. Choose if you want to visualize-setup? If on, the world is colored to represent shortest paths with the darkest patches further from an exit and the lighter patches closer to an exit
8. Press setup (a firealarm will sound at the end of setup, but only for a few seconds!)
9. Either go once or go forever
10. Watch the simulation and take note of the data below the screen!
Note: If you go once, you can utilize the grow-fire button.
      If you choose the go-forever button, the model will run until everyone is either saved or trapped






## THINGS TO NOTICE

  * Notice how the amount of people effects evacuation - typically it takes less time with less people because the exit paths are less crowded. Exits become very conjested when there are more people in the building and it becomes more difficult to leave. 
  * A fire drill is faster than a real fire because the fire drill uses the most efficient way out for everyone, however the real fire has a fire blocking paths, so sometimes people have to go to a further exit
  * The chaos levels of individuals effect how fast they get out of the building. Typically the chaotic people get out the fastest, next the worried people, then the patient people
  * Even though chaotic people get out the fastest, they cause others to go slower. So, when the chaos level is high, evacuation takes longer than normal chaos levels. The low chaos levels also take longer because they are "laid back" about the fire. 




## THINGS TO TRY

  * Try different fire locations and sizes to see how time of fire drill is effected
  * Try different chaos levels - which chaos level has the fastest evacuation time? What does this say about how people should behave during a real fire? 
  * Try different floorplans - which is more effective? are they designed well for evacuation? how could these floorplans be improved? 
  * Overall, what steps should be taken to ensure the most efficient evacuation?



## EXTENDING THE MODEL


**POSSIBLE EXTENSIONS**

  * Represent different floors of a building, so people on higher floors will have to move down the stairs and to the ground floor
  * Implement grow forever: start a fire and grow continiously while people are trying to exit the building, modeling how fires grow over time
  * Including firemen and emergency response teams so they could extinguish the fire
  * Instead of just trapped, count when people die in the fire 
  * Include windows, so if someone is trapped they can try to go out the window


## NETLOGO FEATURES

  * resize-world - to fit the world to our imported images
  * set-patch-size - allow the screen to fit the window depending on our image
  * user-message - broadcasts messages if there are errors in user input and when the drill is over
  * shade-of - clean up a floorplan by setting all shades of blue patches (or red, black, green, white) to be blue. This ensures all patches will be classified correctly



## RELATED MODELS


  * The Earth Science : Fire model shows how a fire spreads in a forest. That would be helpful to look at as you try to implement a continuously growing fire in the building.



## CREDITS AND REFERENCES

  * Utilized many of Matthew Dickerson's Lab Codes. This is commented in the code.
  * Forrest Hall Floor at Plan Middlebury College:  http://www.middlebury.edu/system/files/media/FRE%20FRW%20Forest%20img%20binder.pdf
  * McCardell Bicentennial Hall Floorplan: http://www.middlebury.edu/media/view/249612/original/McCardell_BiHall_1st_floor.pdf
  * Middlebury College Fire Evacuation Guidelines: 
http://www.middlebury.edu/er/protocols/fire
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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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
