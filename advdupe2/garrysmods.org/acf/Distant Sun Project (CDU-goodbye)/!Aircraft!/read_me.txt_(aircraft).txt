@name Read me.txt (Aircraft)

#--------------------------------------------------------------------------------------------------------------#
####The aircraft section contains aircraft both rotor wing and fixed wing vehicles as well as two unique drones
#--------------------------------------------------------------------------------------------------------------#

####Contents
#**means read me. Some aircraft have unique features such as the H-5 that have their own controls

#general plane controls**
#general Heli controls (Pilot)**
#general Heli controls (Gunner)**

#H-5 (Heli)**
#H-10 (Heli)
#H-52 (Heli)
#SA-54 Marrooner/Mauruder (Plane)**
#Naught E-200 Puff (Plane)
#SA-15 Stinger(Plane)**
#SA-3 Timber (Plane)
#SA-50N1 Orient (Plane)
#SA-60 Thunder (Plane)
#ZcH-5 Ghost (Drone)**
#ZcH-6 Stratrohunter (Drone)**


####General fixed wing controls
#Shift -                toggle first person/thrid person
#W/S -                  Throttle Up Down respectively
#D/A -                  Roll Right Left respectively
#Mouse 2 -              Freecam , Look around
#M. up(Prev Weapon) -   Toggle zoom
#H  -                   Toggle VTOL
#Mouse 1 -              Fire gun (/ fire selected weapon if more than two presets)
#Space -                Fire secondary weapon (/ Cycle weapon selection if more than two presets)
#CTRL -                 Flares 



####General rotor wing controls (Pilot)
#Light (F) -            Start/stop engine
#Shift (held) -         toggle first person/thrid person
#W/S -                  Collective up/down respectively
#D/A -                  Roll Right Left respectively
#Mouse 2 -              Cycle through weapons (with more than two presets)
#M. up(Prev Weapon) -   Toggle zoom
#Mouse 1 -              Fire gun (/ fire selected weapon if more than two presets)
#Space -                Toggle hover
#CTRL -                 Flares
#R -                    Reload Weapons
#Arrow keys -           Steer MCLOS weapon (Red Crest ATGM)



####General rotor wing controls (Gunner)
#Mouse 1 -              Fire gun (/ fire selected weapon if more than two presets)
#Space -                Cycle through weapons (with more than two presets)
#Mouse 2 -              Hold gun
#Q -                    toggle first person/thrid person
#CTRL -                 Flares
#R -                    Reload 



####Chundair H-5 Orion####
#**Has additional controls

"Stealthed reconnaissnce helicopter with artillery designator, short range radar and can be harmed with air and ground missiles"

#2x 60mm Anti-tank grenade launchers
#Laser designator
#R3S1 Radar
#4x LATREL Stringray
#4x ATGM FLY II
#3x flare port

#Additonal controls: To toggle radar mode press Q in pilot or Shift in gunner seat. 
#Search mode - displaces vehicles on HUD up to a range of 250m at a arc of 45*
#targeting mode - Semi active radar guidance mode for the ATGMs and designator to stay on target at a range of 350m at 5*

#the air to air missiles will most likely misfire on the first time used because of the props on the way :(, didnt fix this
#if no target is aquired through the radar, the ATGMs will default to SACLOS guided to you mouse position



####Chundair H-10 Gadfly####

"utility heli with various arnaments or unarmed versions, or maek your own preset"

#uses the REDCREST ATGM. MCLOS guidance means you steer them with arrow keys



####Chundair H-52 Cometeer####

"light attack heli"

#Controls are similar to H-2 Attacker



####Chundair SA-54 marooner####

"Naval turboprop aircraft"

#Torpedos will not work on acf3, and are illegal on 2 anyway

#Bombs have been known to be duds because bomb doors are hard to make them possible

#The marauder is the ground attack variant and has multiple weapon presets

#The last seat way in the back is the navigator and sonar operator and wheil has no controls, someone needs to sit in the
#seat in order for the downwards, facing radar to opperate on both his and pilots HUD



####Naught E-200 Puff####

"naught E-200 Puff/ Chundair SA-39 gangajang-E is a stealthier version of the all purpose jet with internal missile bay"
#radar lock is optional for missile guidance and only indicates what the missile should lock onto to avoid collateral


####Chundair SA-15 Stinger####

#Additional control: Q toggle sweep wings. Sweeping the wings give better accleration and top speed at the cost of agility
#and lift

####Chundair SA-3 Timber####

"First plane i made"



####Chundair SA-50N1 Orient####

"Has nati ship missiles with radar lock on guidance"



####Chundair SA-60 Thunder####

"Plane with a lot of weapon."



####ZcH-5 Drone####

"old Helicopter drone, based on versus heli E2"

#Will still move when not in seat

#Controls as following:

#Light (F) -            Start/stop engine
#W/S -                  Set altitude at local waypoint
#M. up(Prev Weapon) -   zoom increment
#Shift -                Toggle FLIR
#Space -                Cycle drone mode

#Waypoint mode:
#Mouse 1 -              Set Waypoint to move to

#designator mode:
#Mouse 1 -              Arm designator
#Mouse2 (while holding M1) - Request fire on designator

#weapon mode:
#Mouse 1 -              would Fire weapon, but is unarmed anyway



####ZcH-6 Drone####

"One of my favorite builds, a fully autonamous jet drone with smart systems although not without flaws everything below
needs to be read if you want to know how to operate all its features"

#Will still move when not in seat

#W/S -                  Set speed to move at
#Shift + W/S -          Set altitude at local waypoint
#Light (F) -            Toggle FLIR
#Space -                Cycle drone mode
#M. up(Prev Weapon) -   zoom increment

#Waypoint mode:
#Mouse 1 -              Set single Waypoint to move to (cancels other waypoints)
#Shift+ Mouse1 -        Set the multiple/next waypoint to move to (loops when reached last point)

#designator mode:
#Mouse 1 -              Arm designator
#Mouse2 (while holding M1) - Request fire on designator

#weapon mode:
#Mouse 1 -              Attack position or entity 

#When in attack mode if at a position, will do a single salvo, if at a entity will attack until entity is dead
#dont attack near map border because it will crash itself

#Drone Chat commands (usable by who last sits in terminal seat):
#Chats cant double- eg 'move','move' twice unless you said anything else prior

#Waypoint -             Sets a new waypoint at Users look pos (similar to Shift+M1)
#Move -                 Cancels current waypoints and sets drone to move to users look pos (similar to M1)
#Stat -                 
#talk - 
#fuel -                 Fuel level
#off -                  Turns drone off. sitting in the seat will turn it back on
#land -                 Lands on this prop: "models/props_phx/huge/road_long.mdl" if there is enough open space 
#Attack /Attack "player" - similar to M1 with weapon mode. attack a player or users aim pos or aim entity.
#halt -                 Stops current task (attack, land) and resume last waypoint(s)

#Can also land on the flagship class carrier with land command
