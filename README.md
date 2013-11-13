warsow.tutorial
===============

Warsow tutorial gametype repo



    Vic:
Not to mention the fact that such a tutorial would need to be localized since 60-70% of German, Russian and probably French users can't read or speak English at all.



    Crizis:
20:46 i have info ballots ready
20:46 activated on classaction press on location, playing narration soundtrack and timed subtitles
20:46 to give instructions inside the tutorial map

20:48 idea of the tutorial map was to show all jumping shits and whatever

20:48 and at the end of the level, throw the player into botmatch like in ql
20:48 so your job would be to script this whole base for botmatch

20:49 - the movement tutorial is done in warmup mode
20:49 - at the end of the map, trigger of some kind should add a bit into the game, respawned in the match arena outside the actual movement map
20:50 1) so first part is to make a *trigger* to add a bot into the game (any function in gt script that can be triggered with brush or other code)
20:51 2) when player readies up, they get spawned inside the fighting arena
20:51 little detail here is that in warmup, player should spawn in predefined spawn rather than the regular random spawn

20:52 like info ballots are just a class like turrets that create misc_infoballot entities

//
15:07 ye ofc
15:08 you'll likely have to plan the tutorial structure a bit
15:08 map was made like it would show first show bunnyhopping, walljumping etc and explain them at each location with ballot
15:08 idea of first hallway was to reach the door in the corridor with bunnyhopping
15:08 you can't walk there as it closes before..
15:08 got the idea?
15:08 
15:09 map itself could have some transparent neon signs and whatnot to show routes, i can do work like that if needed
15:09 and everything mapping related
