;---------------------------------------------INFO-------------------------------------------------

; HOMEWORK 2: Pandemic Modeling

; DUE DATE: Tuesday, February 2, 2021 (by 5am)

; LAB PARTNER: Matthew Kushwaha

; PROFESSOR HELP: Professor Dickerson
     ; I used the sample pandemic model from class and expanded on the functions
     ; and modified some of the previous code

; BONUS: I expanded on all 5 of the extra features (my main one was vaccines), I explained each section
;        in the info tab - sources are at the bottom


; Comments are made throughout each function to explain my reasoning, a more detailed overview of
;    my reasoning is in the info tab



;---------------------------------------------CODE-------------------------------------------------






;--------------------- VARIABLES --------------------



; Breeds
breed [ buildings building ]
breed [ people person ]



; Instance Variables
buildings-own [ closed? function ]

people-own [
  house
  age
  sex
  high-risk?
  mask?

  isolating?
  social-distancing?
  time-left-sd

  vaccine-status
  days-since-exposure               ; -1 = not exposed
  days-to-be-sick
  mortality-chance
]



; Globals
globals [
  CLR-asymp       ; Colors help visualize status of individual
  CLR-symp
  CLR-not-inf
  CLR-immune

  p1               ; no masks
  p2               ; only uninfected is wearing a mask
  p3               ; only infected person has mask
  p4               ; both person has masks

  mortality-ct
  phase

  p-social-distance   ; probability of social distancing
  p-going-out         ; probability of going to a building



]



; Globals On Interface
    ; population ................... number of people
    ; mask-prob .................... probability that a person wears a mask
    ; percent-initially-exposed .... percent of population initially exposed
    ; isolation-probability ........ probability that one will isolate if symptomatic
    ; vaccines-per-tick ............ vaccines per tick (day)

    ; model-COVID? ................ If yes - uses COVID stats, if no - uses user input

    ; doses ........................ number of doses
    ; p1dose ....................... effectiveness of 1 dose
    ; p2dose ....................... effectiveness of 2 doses
    ; days-between-doses ........... days between doses



    ; p-symptomatic ................ probability of being symptomatic
    ; average-days-sick ............ average days a person is sick (after infection/symtpoms arrive)
    ; days-until-contagious ........ days after exposure that a person is contagious
    ; days-until-symptoms .......... days after exposure that a person will become (a)symptomatic
    ; average-mortality-rate ....... average chance of dying upon recovery





; ================================================= SETUP PROCEDURES ==================================================


; Observer Context
; Initiates globals, creates world andcreates people
to setup
  ca
  reset-ticks

  init-globals
  init-world
  populate

end



; Observer Context
; Initializes globals
to init-globals
  set CLR-asymp   yellow
  set CLR-symp    red
  set CLR-not-inf green
  set CLR-immune  blue

  set p1 .9                          ; "Very High"
  set p2 .6                          ; "High"
  set p3 .4                          ; "Medium"
  set p4 .1                          ; "Low"

  set mortality-ct 0
  set phase 3

  set p-social-distance min-p-social-distance
  set p-going-out .2


  if model-COVID? = true [          ; If modeling COVID - set variables to COVID data

   ; VIRUS VARIABLES
    set p-symptomatic .80           ; 80% are symptomatic
    set average-days-sick 10
    set days-until-symptoms 6
    set days-until-contagion 4      ; 2 days before symptomatic

   ; VACCINE VARIABLES
    set days-between-doses 28        ; 95.6 % effective
    set doses 2                      ; 2 Doses for Moderna
    set p1dose .802                  ; 80.2 % effective
    set p2dose .956                  ; 95.6 % effective
  ]
end



; Observer Context
; Initiates world (creates buildings)
to init-world

  ; Grocery Store
  create-buildings 1 [
    setxy 10 10
    set size 3
    set color 26
    set shape "building store"
    set label "GROCERY STORE"

    set closed? false
    set function "grocery store"
  ]

  ; Gym
  create-buildings 1 [
    setxy -10 10
    set size 3
    set color 26
    set shape "house"
    set label "GYM"

    set closed? false
    set function "gym"
  ]

  ; Resturaunt
  create-buildings 1 [
    setxy 10 -10
    set size 3
    set color 26
    set shape "food"
    set label "RESURAUNT"

    set closed? false
    set function "resturaunt"
  ]

  ; School
  create-buildings 1 [
    setxy -10 -10
    set size 3
    set color 26
    set shape "building institution"
    set label "SCHOOL"

    set closed? false
    set function "school"
  ]

  ask patches [set pcolor black ]
end



; Observer Context
; Creates people and initializes their instance variables
to populate
  create-people population [
    set color CLR-not-inf                  ; Color
    set size 1

    setxy random-xcor random-ycor          ; Location
    set house patch-here

    set days-since-exposure -1                   ; Instance variables
    set isolating? false
    set social-distancing? false
    set high-risk? false

    decide-age                             ; Demographics
    decide-sex
    decide-risk
    decide-mask
  ]

  initially-infect
end










; ---------------------- Populate Demographic Procedures -------------------

; Turtle Context
; Assigns age based on probability
to decide-age
  let chance random-float 1             ; choose random percent between 0-100

  if chance <= .25 [                    ; 0-19 years old = 25% chance
     set age random 20
  ]
  if chance > .25 and chance <= .65[    ; 20-49 years old = 40% chance
     set age (random 30) + 20
  ]
  if chance > .65 and chance <= .89 [   ; 50-69 years old = 24 % chance
     set age (random 20) + 50
  ]
  if chance > .89 [                     ; 70+ years old = 11 % chance
     set age (random 30) + 70
  ]
end



; Turtle Context
; Decides sex based on probablity
to decide-sex
  ifelse random-float 1 > .49 [ set sex "female" ] [set sex "male" ]
end



; Turtle Context
; Decides if high risk based on probability
to decide-risk

  let chance random-float 1
   if age <= 19 [
      if chance <= .001 [ set high-risk? true ]
     ]
   if age > 19 and age <= 49 [
      if chance <= .0244 [ set high-risk? true ]
     ]
   if age > 49 and age <= 69 [
      if chance <= .106 [ set high-risk? true ]
     ]
   if age >= 70 [
      if chance <= .192 [ set high-risk? true ]
     ]

end



; Turtle Context
; Decides mask wearing based on probability
to decide-mask
   ifelse random-float 1 < mask-prob [          ; Mask
      set mask? true
      set shape "masked-person"
    ][                                          ; No mask
      set mask? false
      set shape "person"
    ]
end












; ---------------------- Initially Infect Procedures -------------------


; Observer Context
; infects people based off percent-initially-infected slider
to initially-infect
  repeat ((percent-initially-exposed / 100) * population) [ infect-one-person ]
end



; Observer Context
; infects one person
to infect-one-person
  ask one-of people with [not-exposed?] [ be-exposed ]
end














; ============================================== MAIN LOGIC & GO PROCEDURES ==============================================



; Observer Context
; Main movement of the program - decides phases, vaccinates, moves people, updates infections and handles new infections
; 1 tick for each cycle of go
to go

  decide-phase             ; decide current phase

  vaccinate-people         ; give out vaccines

  ask people [             ; Move & update people's infection status
      move
      update-infection
  ]

  new-infections           ; Handle new infections based off location

  tick
end










; ---------------------------- PHASE PROCEDURES -------------------------

; PHASE 1: +25% percent infected |  PHASE 2: 15-25% INFECTED  | PHASE 3: under 15%

; Observer Context
; Decides phase based of population currently infected
to decide-phase

  let percent-infected ( count people with [infected?] / count people)

  if percent-infected >= .25 [
    set phase 1
    enact-phase1
  ]

  if percent-infected >= .15 and percent-infected < .25 [
    set phase 2
    enact-phase2
  ]

  if percent-infected < .15 [
    set phase 3
    enact-phase3
  ]

end



; Observer Context
; Enacts phase 1 plans
to enact-phase1
  set p-social-distance min-p-social-distance + .1                      ; increase social distancing probability
  set p-going-out .1                                                    ; reset going-out probability
  ask buildings with [function != "grocery store"] [set closed? true]   ; Close all but grocery store
end



; Observer Context
; Enacts phase 2 plans
to enact-phase2
  set p-social-distance min-p-social-distance + .1                      ; increase social distancing probability
  set p-going-out .15                                                   ; reset going-out probability
  ask buildings [set closed? false]
  ask buildings with [ function = "gym" ] [ set closed? true]           ; Open all but gyms
end



; Observer Context
; Enacts phase 3 plans
to enact-phase3
    set p-social-distance min-p-social-distance                          ; set social-distancing to minimum
    set p-going-out .2                                                   ; reset going-out probability
    ask buildings [set closed? false]                                    ; open all bildings
end









; ---------------------------- VACCINATION PROCEDURES -----------------------------

; VACINE STATUS:   0 = no vaccine | 1+ = one dose | -1 = 2 doses (fully vaccinated)


; Observer Context
; Vaccinates turtles with certain amount of vaccinations per tick
; Prioritzes those with 1 dose, then high risk, then others
     ; (has option for 1 or 2 doses based on user input)
to vaccinate-people

  let vaccines-left vaccines-per-tick


  while [ any? people with [ vaccine-eligible? ]  and (vaccines-left > 0) ] [

    if doses = 2 [                                                                                         ; FOR 2 DOSES

      (ifelse ( any? people with [vaccine-status > days-between-doses] with [vaccine-eligible?] ) [                  ; Prioritize those who are eligible for second dose
        ask one-of people with [vaccine-status > days-between-doses] with [vaccine-eligible?] [get-second-dose]
        ]

        any? people with [high-risk? = true ] with [vaccine-eligible?] with [vaccine-status = 0] [
        ask one-of people with [high-risk? = true] with [vaccine-eligible?] with [vaccine-status = 0] [ get-first-dose ]   ; else, give first dose to high-risk person
      ][

          ask one-of people with [vaccine-eligible?] with [vaccine-status = 0 ] [ get-first-dose  ]                        ; else, give first dose to eligible person
      ])

    ]

    if doses = 1 [                                                                                          ; FOR 1 DOSE

      ifelse any? people with [high-risk? = true ] with [ vaccine-eligible?] [                                 ; vaccinate high risk people first
        ask one-of people with [high-risk? = true] with [vaccine-eligible?] [ get-second-dose ]
      ][
         ask one-of people with [vaccine-eligible?] [ get-second-dose ]                                        ; else, vaccinate new person
      ]
    ]
       set vaccines-left (vaccines-left - 1)                                                              ; DECREASE VACCINES LEFT BY 1
  ]


   if any? people with [vaccine-status > 0] [                                                               ; Increase days since first dose for all with first dose
      ask people with [vaccine-status > 0] [ set vaccine-status  (vaccine-status + 1)]
   ]
end




; Turtle Context
; reports if turtle is eligible for a vaccine
; NOTE; immune people do not need vacines, however if you could get the virus twice, then they would
to-report vaccine-eligible?
  if infected? or vaccine-status = -1 or age <= 18 or immune? [ report false ]

  if vaccine-status > 0 and vaccine-status <= days-between-doses [ report false ]

  report true
end



; Turtle Context
; Gives first dose
to get-first-dose
  set vaccine-status 1
end


; Turtle Context
; Gives second dose
to get-second-dose
  set vaccine-status -1
end


; Turtle Context
; reports if a turtle is fully vaccinated
to-report vaccinated?
  report vaccine-status = -1
end












; ---------------------------- MOVEMENT PROCEDURES -----------------------------


; Turtle Context
; Individual movement of turtles based on current state of turtle and probability
; More detail of movement is in the comment throughout the code
to move

  if social-distancing? [                                                      ; If social distancing, distance or stop distancing
    ifelse time-left-sd = 0 [ stop-social-distancing ]
                         [ set time-left-sd time-left-sd - 1 ]
  ]

  if social-distancing? = false [                                              ; If not social distancing

    if symptomatic? [ ifelse isolating? [ go-home ] [ wander ] ]                     ; If symptomatic, either isolate or wander

    if not symptomatic? [                                                            ; If not symptomatic

       if inside? [                                                                       ; If inside, leave building and wander
         leave-building
         wander
       ]

       if outside? [                                                                       ; If outside

          let chance random-float 1

          if immune? [                                                                          ; If immune, either go out or wander
            ifelse chance <= p-going-out [ go-out ] [ wander ]
        ]
        if not immune? [                                                                        ; If not immune - social distance, go out or wander

          (ifelse chance <= p-social-distance [ social-distance ]

                  chance <= ( p-social-distance +  p-going-out)  [ go-out ]

                  [ wander ] )
        ]
      ]
    ]
  ]
end





; Turtle Context
; Makes turtle go home
to go-home
  move-to house
end


; Turtle Context
; Begins social distancing for turtle
to social-distance
  go-home
  set time-left-sd 3
  set social-distancing? true
  if visualize-distancing? [ ask patch-here [ set pcolor 67 ]]

end


; Turtle Context
; Ends social distancing for turtle
to stop-social-distancing
  ask patch-here [set pcolor black ]
  set social-distancing? false
end



; Turtle Context
; Moves turtle to one of open buildings
to go-out
  move-to one-of buildings with [closed? = false]

  rt random 361           ; ensures turtles are still inside, but not all on top of eachother
  fd random-float 3
end



; Turtle Context
; Makes turtle leave the building
to leave-building
  rt ( 10 - random 21 )
  fd 2
end





; Turtle Context
; Makes Turtle Wander
; Note: tries to avoid wandering into symptomatic patients and buildings
;       but prioritizes avoiding symptomatic patients then buildings if avoiding both is not possible
; (Comments thoughout may help with understanding)
to wander
  rt ( 10 - random 21 )

  ; If uninfected and facing a patch with infected person or building, try to change
  if uninfected? and ( [ any? people-here with [symptomatic?]] of patch-ahead 1  or [ any? buildings-here ] of patch-ahead 1 ) [

     ; if any neighbors without symptomatic and building - face there
     (ifelse any? neighbors with [not any? people-here with [symptomatic?]] with [not any? buildings-here][
       face one-of neighbors with [not any? people-here with [symptomatic?]] with [not any? buildings-here]
     ]

     ; else if any without symptomatic people - face there
     any? neighbors with [not any? people-here with [symptomatic?]] [
       face one-of neighbors with [not any? people-here with [symptomatic?]]
     ]

     ; else if any without buildings, - face there
     any? neighbors with [not any? buildings-here ] [
       face one-of neighbors with [not any? buildings-here]
     ] [
     ; final else just dont turn
       face [heading] of self
      ])
  ]

   fd 1
end
















; ---------------------------- UPDATE INFECTIONS PROCEDURES -----------------------------





; Turtle Context
; Updates infection and decides if person fights off virus, if they are symptomatic and if they die or become immune
; Comments throughout will aid with understanding
to update-infection

  if days-since-exposure >= 0 [                                                    ; If previously exposed to virus
    set days-since-exposure days-since-exposure + 1                                         ; Increase days since exposure

    if days-since-exposure = days-until-contagion [                                ; DAYS SINCE EXPOSURE = DAYS UNTIL CONTAGIOUS

      let chance random-float 1                                                  ; If vaccinated, give chance to fight off virus else, become-contagious

      if vaccine-status = -1 [                                                      ; 2 Doses
        ifelse chance <= p2dose [ become-uninfected ] [ become-contagious ]
      ]

      if vaccine-status > 0 [                                                       ; 1 Dose
        ifelse chance <= p1dose [ become-uninfected ]  [ become-contagious ]
      ]

      if vaccine-status = 0 [ become-contagious]                                    ; Not vaccinated - become contagious
    ]

    if days-since-exposure = days-until-symptoms [                                 ; DAYS SINCE EXPOSURE = DAYS UNTIL SYMPTOMS | decide if symptomatic or asymptomatic
      ifelse random-float 1 < p-symptomatic [ become-symptomatic] [ become-asymptomatic ]
    ]


    if days-since-exposure = days-to-be-sick [                                     ; DAYS SINCE EXPOSURE = DAYS TO BE SICK | die or become immune

      decide-mortality                                                             ; Decide mortality based on age and population infected

      ifelse random-float 1 <= [mortality-chance] of self [                        ; DIE
        finish-isolating
        set mortality-ct mortality-ct + 1
        show " died of virus."
        die
      ][                                                                           ; IMMUNE (recover)
        show "recovered from virus and is now immune."
        become-immune
      ]
    ]
  ]

end



; Turtle Context
; Decides mortality chance based off age (or normal distribution), high-risk and current population infected
to decide-mortality

  ;INITIAL MORTALITY RATE

    ifelse model-COVID? = true [           ; COVID MORTALITY BASED OFF AGES

       if age <= 19 [                      ; 0-19 years old = .00003 aka .003 %
         set mortality-chance .00003
       ]
       if age > 19 and age <= 49 [         ; 20-49 years old = .0002 aka .02%
         set mortality-chance .0002
       ]
       if age > 49 and age <= 69 [         ; 50-69 years old = .005 aka .5%
         set mortality-chance .005
       ]
       if age >= 70 [                      ; 70+ years old = .054 aka 5.4%
         set mortality-chance .054
       ]
    ][                                     ; else - USER DECIDED MORTALITY RATES BASED OFF NORMAL DISTRIBUTION

       set mortality-chance random-normal average-mortality-rate .2
    ]

  ; INCREASE MORTALITY RATE (based off current conditions)

  ; High Risk
  if high-risk? [ set mortality-chance (mortality-chance * 2) ]

  ; Percent population infected
  let percent-infected (count people with [infected?] / count people) * 100       ; increase mortality by .05 for every 10% of population that is infected
  let increase round (percent-infected / 10)
  set mortality-chance (mortality-chance + (increase * .05))

  if mortality-chance > 1 [ set mortality-chance 1 ]                              ; If mortality is over 1, set to 1

end






; ---------------------------- NEW INFECTIONS PROCEDURES -----------------------------


; Observer Context
; Turtles who are infected (and not social isolating) will expose turtles
;    that have not been exposed and are not social distancing
to new-infections

  ask people with [infected?] with [isolating? = false] [
    ask people in-radius 1 with [not-exposed?] with [social-distancing? = false] [ be-exposed-by myself ]     ; Can't be exposed if social distancing
  ]
end





; Turtle Context
; [ p ] --> person with virus who is exposing person (self)
; Probabilitys of transmission based of mask wearing
to be-exposed-by [ p ]
  if mask? and [mask?] of p            [ if random-float 1 < p4 [ be-exposed ]]
  if not mask? and [mask?] of p        [ if random-float 1 < p3 [ be-exposed ]]
  if mask? and not [mask?] of p        [ if random-float 1 < p2 [ be-exposed ]]
  if not mask? and not [mask?] of p    [ if random-float 1 < p1 [ be-exposed ]]
end









; Turtle Context
; Exposes a turtle to the virus and determines days to be sick
to be-exposed

  set days-since-exposure 0                                                          ; Turtle exposed but not yet infected / contagious

  let dtbs-float days-until-symptoms + random-normal average-days-sick 3       ; Decide days sick by a normal distribution based off average days sick
  let dtbs-int int dtbs-float
  let dtbs-carry dtbs-float - dtbs-int

  set days-to-be-sick dtbs-int                                                 ; Appropriately round float for to integer
  if random-float 1 < dtbs-carry [set days-to-be-sick days-to-be-sick + 1]

end













; ============================================== HELPER PROCEDURES & REPORTERS ==============================================



;-------- ISOLATE FUNCTION ------------

; Turtle Context
; Isolates infected turtle
to isolate
  go-home
  set isolating? true
  ask patch-here [set pcolor 17]

end


; Turtle Context
; Stops Isolating Turtle
to finish-isolating
  ask patch-here [set pcolor black]
  set isolating? false
end






;----------- Procedures that Change the State of a Turtle ---------------

;; ALL TURTLE CONTEXT


; Become contagious by being asymptomatic (until decided if symptomatic)
to become-contagious
  become-asymptomatic
end



to become-asymptomatic
  set color CLR-asymp
end


to become-symptomatic
  set color CLR-symp
  if random-float 1 <= isolation-probability [isolate]
end




 ; If exposed to virus but body fights it off
to become-uninfected
  set color CLR-not-inf
  set days-since-exposure -1
end



; Recover from the virus
to become-immune
  set color CLR-immune
  set days-since-exposure -1
  finish-isolating
end





;-----------  IMPORTANT REPORTERS ---------------


; Not exposed, immune, or infected
to-report not-exposed?
  report  days-since-exposure = -1 and not immune?
end



; Not currently infected  or immune, does count those exposed (same as testing negative)
to-report uninfected?
  report not infected? and not immune?
end



; Recovered from virus and immune
to-report immune?
  report color = CLR-immune
end



; People who are infected (same as testing positive)
to-report infected?
  report color = CLR-symp or color = CLR-asymp
end


to-report symptomatic?
  report color = CLR-symp
end


to-report asymptomatic?
  report color = CLR-asymp
end



; Inside a building
to-report inside?
  report any? buildings-on neighbors
end


; Outside a building
to-report outside?
  report not inside?
end


@#$#@#$#@
GRAPHICS-WINDOW
316
52
717
454
-1
-1
10.622
1
10
1
1
1
0
1
1
1
-18
18
-18
18
0
0
1
ticks
30.0

BUTTON
103
423
169
456
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
66
55
224
88
population
population
200
1000
375.0
25
1
Persons
HORIZONTAL

SLIDER
80
100
202
133
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
952
490
1002
535
Deaths
mortality-ct
17
1
11

BUTTON
32
478
119
511
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
153
479
234
512
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
76
538
191
571
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
52
149
263
182
percent-initially-exposed
percent-initially-exposed
0
100
10.0
1
1
NIL
HORIZONTAL

PLOT
252
459
421
609
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
"default" 1.0 0 -16777216 true "" "plot ((count people with [infected?]) / population) * 100"

SLIDER
73
197
222
230
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
882
553
988
598
People Recovered
count (people with [immune?])
17
1
11

SLIDER
772
257
948
290
average-mortality-rate
average-mortality-rate
0
1
0.2
.01
1
NIL
HORIZONTAL

SWITCH
448
11
580
44
model-COVID?
model-COVID?
0
1
-1000

SLIDER
746
139
845
172
p1dose
p1dose
0
.99
0.802
.01
1
NIL
HORIZONTAL

SLIDER
856
138
955
171
p2dose
p2dose
p1dose
1
0.956
.01
1
NIL
HORIZONTAL

TEXTBOX
794
119
944
137
VACCINE EFFECTIVENSS
11
0.0
1

TEXTBOX
783
55
952
97
VACCINE SPECIFICATIONS\n
12
0.0
1

SLIDER
773
216
948
249
p-symptomatic
p-symptomatic
0
1
0.8
.01
1
NIL
HORIZONTAL

SLIDER
772
303
944
336
average-days-sick
average-days-sick
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
772
384
946
417
days-until-symptoms
days-until-symptoms
0
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
772
341
946
374
days-until-contagion
days-until-contagion
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
843
76
991
109
days-between-doses
days-between-doses
1
40
28.0
1
1
NIL
HORIZONTAL

SLIDER
731
77
823
110
doses
doses
1
2
2.0
1
1
NIL
HORIZONTAL

MONITOR
867
490
917
535
NIL
phase
17
1
11

SWITCH
61
297
224
330
visualize-distancing?
visualize-distancing?
1
1
-1000

PLOT
614
459
822
609
% Population Fully Vaccinated
Time (Ticks)
% Vaccinated
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "\n plot (count people with [vaccine-status = -1] / population) * 100\n  "

SLIDER
61
356
226
389
isolation-probability
isolation-probability
0
1
0.5
.01
1
NIL
HORIZONTAL

TEXTBOX
62
22
234
54
 IF model-COVID? IS ON: 
14
0.0
1

TEXTBOX
312
21
434
39
PANDEMIC MODEL:
13
0.0
1

TEXTBOX
599
10
716
52
If on, stats from the COVID-19 Pandemic will be used
11
0.0
1

SLIDER
62
246
230
279
min-p-social-distance
min-p-social-distance
0
.80
0.8
.01
1
NIL
HORIZONTAL

TEXTBOX
774
18
947
52
 IF model-COVID? IS OFF: 
14
0.0
1

TEXTBOX
806
183
938
213
VIRUS SPECIFICATIONS
12
0.0
1

PLOT
437
459
601
609
% Infected w/o Masks
Time (ticks)
% People 
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if (count people with [infected?] + count people with [immune?]) != 0 [\nplot (count people with [infected?] with [mask? = false] + count people with [immune?] with [mask? = false])/ (count people with [infected?] + count people with [immune?]) * 100\n]"

@#$#@#$#@
## WHAT IS IT?


This is a simplified model of a pandemic. The program has the ability to use statistics from ongoing the COVID-19 pandemic, including average mortality rates based on age, vaccine distribution/effectiveness, average days until contagious, average days until symptomatic, average days sick, probability of being symptomatic and different phases put into place. The program also gives the ability to the user to change these variables to test the different outcomes of these variables. Plots and monitors allow the user to see useful statistics of the pandemic being modeled. 




## HOW IT WORKS





### **GENERAL DESIGN FEATURES**

  * Recovery time is based off of a normal distribution of average days sick (can be determined by a slider)
  * To infect people, you can either infecting a certain percentage of the initial population (slider), infecting one person at a time (button), or a mix of both
  * To help visualize the pandemic, I created monitors for current phase, death toll and number of people recovered. I also created plots of percent of people infected which helps visualize the idea of "flattenning the curve", percent of population vaccinated and percent infected without masks.
  * **Social Distancing**:
    * A person has a chance of social distancing based on the variable min-p-social-distance
    * If a person decides to social distance, they do it for 3 days 
    * A person cannot be infected while social distancing (representing staying in their house)
    * The probability of social-distancing increased based on the current phase, phase 3 is min-p-social-distance and each phase lower is +0.1 
    * You can choose to visualize social distancing (switch) which will show a light green patch around the person
  * **Isolation:**
    * Similar to social distancing, once a person becomes symptomatic they have a probability of isolating based on a global variable
    * Isolation will send a person home and they cannot infect anyone else
    * Isolation is visualized by a light red patch around a symptomatic individual
    * Isolation ends when a person becomes immune or dies
  * **Demographics:**
    * Demographics based off of the US Census 2019
    * AGE:
      * 0-19  ..... 25%
      * 20-49 ..... 40%
      * 50-69 ..... 24%
      * 70+   ..... 11%
    * SEX - 49% Male and 51% Female
  * **High Risk Individuals:**
    * Data based off a COVID-19 study of percent of age groups at higher risk for COVID
    * Risk Based on Age: 
      * 0-19 .... 0.001 (0.1%)
      * 20-49 ... 0.0244 (2.4%)
      * 50-69 ... 0.106 (10.6%)
      * 70+ ..... 0.192 (19.2%)    
  * **Other COVID-19 Specifications**
    * Average days until symptom onset ........ 6
    * Days before symptoms when contagious .... 2
    * Average days sick after symptom onset ... 10
    * 20% Asymptomatic, 80% Symptomatic
  * **Movement**
    * Movement is based off of status of an individual
    * People who are social distancing will continue to social distance for 3 days, then they can move
    * Those that are infected will either go home and isolate or wander 
    * Uninefect, immune and asymptomatic people will either social-distance, go out to a building or wander
    * Wandering people try to avoid going to buildings and symptomatic people, if they cannot do both they will try to avoid symptomatic people and if they can't they will just continue to move forward



### **EXTRA FUNCTIONALITY**




**1. VACCINATION;**
 
  * If the user chooses to model COVID, the vaccination data is based off the Moderna Vaccine due to its high effectiveness
  * Specifications of the Moderna Vaccination:
    * 2 Doses separated by 28 days
    * EFFECTIVENESS:
      * First dose:  80.2%
      * Second dose: 95.6%
  * The user can decide how many vaccinations are given out each tick
  * This program vaccinates high-risk people first and does not vaccinate those under 18 (according to Moderna guidelines)
  * CODE: vaccine-status -> 0 = no vaccine,  1+ = one dose,  -1 = 2 doses
  * If the user is not modeling COVID-19, they can chose number of doses, days between doses and effectiveness of each dose
  * In this model, immune people are not able to get vaccines (to avoid waste)


**2. MORTALITY RATES**
 
  * Inital mortality rates are based off CDC mortality rates based on age groups
  * AGE (based on fatalities per total cases):
    * 0-19  ..... 0.00003 (0.003%)
    * 20-49 ..... 0.0002  (0.02%)
    * 50-69 ..... 0.005   (0.5%)
    * 70+   ..... 0.054   (5.4%)
  * Rate of current mortality chance increases by 50% if a person is high risk
  * Rate of current mortality increase 5% for ever 10% of the population that is currently effected (this represents hospitals being full)


**3. ENVIRONMENT**
  
  * The environment represents a simple town 
  * I added four locations: grocery store, gym, resturaunt and school
  * Turtles have a probability of going to one of these four places (p-going-out), granted it is open (that changes based off phases) 
  * If they are not going to the place directly, they will try to avoid it (mimicing avoiding crowds)
  * Symptomatic turtles will not go to these places


4.**POLICIES AND REGULATIONS**
  
  * PHASES 
    * Phases are based off of Massachussets Phase Reopeing Guidelines
    * Phase number based off % of population infected 
    * Buisnesses are opened/closed based off current phase 
    * Probability of social distancing increases with reduction of phase
    * Probability of going out increases with increase of phases
    







### **SIMPLICFICATIONS**

  * USA based demographic and COVID information, even though modeling a pandemic
  * Doesn't represent travel
  * Peoples ages are constant, doesn't increase with time
  * All vaccines are Moderna Vaccines
  * Inital mortality rates are averages, then when they are changed it is just by estimation based on data, not fact
  * Assumes that once you get the virus you are immune 
  * Social distancing is random, although in real life it is more likely that high risk people will be more likley to social-distance
  * Transmission rates based on mask wearing is assumed percentages based of off estimations
  * Families / Living situations are not considered
  * There are not hospitals, however mortality rates are modeled based off of percentage of population infected
  * NOTE: many things can be improved for this model, however it is just a simple model of a pandemic. This can be used to test out how different regulations can effect infections and mortalities 






## HOW TO USE IT

**STEPS:**

1. Choose if you want to model COVID-19 by using the switch model-COVID?
 **IF YES**
2. Chose values for each of these variables: 
    * population size (slider)
    * percent initially exposed (slider)
    * mask wearing probability (slider)
    * how many vaccines per tick (slider)
    * minimum social distaning probability (slider)
    * isolation probability (slider)
    * turn on/off visualing social distancing (slider
**IF NO** (skip step 3 if model-COVID switch is on)
3. Also choose the following variables:
    * Number of vaccine doses (slider)
    * days between doses (slider)
    * effectiveness of each dose (2 sliders)
    * average mortality rate (slider) 
    * probability of being symptomatic (slider)
    * days until contagious (slider)
    * days until symptoms may appear (slider)
9. Press setup button
10. Either go once or go forever




## THINGS TO TRY

I recommend trying the COVID model with different factors to see how certain regulations can help.

Another interesting thing is to see how "flattening" the curve effects mortality rates. Test different vaccinations, mask wearing, social distancing and isolation probabilities and see if flattening the curve really does help reduce mortality rates. Note - it might take longer for the same amount of people recovered, however really focus on the mortality count.


## EXTENDING THE MODEL

**POSSIBLE EXTENSIONS**

  * Include travel and travel restrictions
  * Experinment with probability of social distancing and isolation, in the real world it is not a fixed value but depends on demographics, risk and many other categories
  * Add a wider environment
  * Add schedules - are there busier times of the day for certain places/
  * Include families and contact tracing - links could be made to trace sources of the virus
  * Improve movement to make it smoother and more methodical


## CREDITS AND REFERENCES

The websites below contain all the information that I used for COVID-19 specific facts in this model

DEMOGRAPHICS:
 https://www.census.gov/data/tables/2019/demo/age-and-sex/2019-age-sex-composition.html

MORTALITY RATES: 
https://www.cdc.gov/coronavirus/2019-ncov/hcp/planning-scenarios.html

HIGH RISK STUDY: 
https://www.thelancet.com/action/showPdf?pii=S2214-109X%2820%2930264-3

VACCINE:
 https://www.bbc.com/future/article/20210114-covid-19-how-effective-is-a-single-vaccine-d

COVID-19 SPECIFICATIONS: 
     https://www.cdc.gov/coronavirus/2019-ncov/if-you-are-sick/end-home-isolation.html
     https://www.cdc.gov/coronavirus/2019-ncov/hcp/planning-scenarios.html
     https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1003346
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

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

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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

food
false
0
Polygon -7500403 true true 30 105 45 255 105 255 120 105
Rectangle -7500403 true true 15 90 135 105
Polygon -7500403 true true 75 90 105 15 120 15 90 90
Polygon -7500403 true true 135 225 150 240 195 255 225 255 270 240 285 225 150 225
Polygon -7500403 true true 135 180 150 165 195 150 225 150 270 165 285 180 150 180
Rectangle -7500403 true true 135 195 285 210

grocery-store
false
0
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 60 105 60 60 240 60 240 105 300 165

gym
false
0
Rectangle -7500403 true true 45 30 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180
Polygon -1 false false 90 75
Line -1 false 135 60 150 90
Line -1 false 150 90 165 60
Line -1 false 150 90 150 120
Line -1 false 180 120 195 60
Line -1 false 195 60 210 90
Line -1 false 210 90 225 60
Line -1 false 225 60 240 120
Line -1 false 105 60 60 60
Line -1 false 60 60 60 120
Line -1 false 60 120 105 120
Line -1 false 105 120 105 90
Line -1 false 105 90 75 90

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

school
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265
Polygon -7500403 true true 150 120 150 105
Polygon -7500403 true true 150 135 150 135 180 120 120 150
Line -1 false 45 120 15 120
Line -1 false 15 120 15 150
Line -1 false 15 150 45 150
Line -1 false 45 150 45 180
Line -1 false 45 180 15 180
Line -1 false 90 120 60 120
Line -1 false 60 120 60 180
Line -1 false 60 180 90 180
Line -1 false 105 120 105 180
Line -1 false 135 120 135 180
Line -1 false 105 150 135 150
Line -1 false 150 120 180 120
Line -1 false 180 120 180 180
Line -1 false 180 180 150 180
Line -1 false 150 120 150 180
Line -1 false 195 120 225 120
Line -1 false 225 120 225 180
Line -1 false 225 180 195 180
Line -1 false 195 120 195 180
Line -1 false 255 120 255 180
Line -1 false 255 180 285 180

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

train
false
0
Rectangle -7500403 true true 30 105 240 150
Polygon -7500403 true true 240 105 270 30 180 30 210 105
Polygon -7500403 true true 195 180 270 180 300 210 195 210
Circle -7500403 true true 0 165 90
Circle -7500403 true true 240 225 30
Circle -7500403 true true 90 165 90
Circle -7500403 true true 195 225 30
Rectangle -7500403 true true 0 30 105 150
Rectangle -16777216 true false 30 60 75 105
Polygon -7500403 true true 195 180 165 150 240 150 240 180
Rectangle -7500403 true true 135 75 165 105
Rectangle -7500403 true true 225 120 255 150
Rectangle -16777216 true false 30 203 150 218

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
