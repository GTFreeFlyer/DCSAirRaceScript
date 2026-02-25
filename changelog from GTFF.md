AirRaceScript4
Changes by GTFreeFlyer, February 2026

• Changed the filename from AirRaceScript3 to AirRaceScript4  
• Added capability to have multiple laps. NumberLaps can be set in the 
   editor without touching the lua script.
• Added option to use a group timer, instead of individual timers so the 
   timer starts for everyone when the first plane enters gate #001.  
• This new version can replace the script in legacy .miz files without 
   breaking them. You will get the new options. The only difference now 
   being that flying backwards through the gates is penalized differently, 
   so just don't do it. This had to be done for new multiple laps feature. 
• If your legacy .miz has multiple laps by overlapping gate zones at each 
   pylon, just leave it as is with the new default settings (laps = 0)
• Updated note about minimum MIST version requirement because the older 
   version of MIST can cause a script error.
• Added some additional sound effects in the repo to give users more options.
• Older miz versions will no longer hear, "You are cleared into the track, 
   smoke on." voiceover play when a player is added to the course.
• Now, by default, illumination flares appear over each gate starting and
   ending at times defined by user. Additional illumination zones are simply
   added by dropping a trigger zone on the map. Option can be disabled too.