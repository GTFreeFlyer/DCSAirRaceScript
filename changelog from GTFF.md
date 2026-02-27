##AirRaceScript4  
Changes by GTFreeFlyer, February 2026  
  
• Changed the filename from AirRaceScript3 to AirRaceScript4  
• Readme updated. Example settings file and suggested .miz breifing text  
   files added to root folder in repo.  
• Added capability to have multiple laps. NumberLaps can be set in the  
   editor without touching the lua script.  
• Added options for group races, instead of individual timers so the  
   timer starts for everyone when the first plane enters gate #001.  
• Updated note about minimum MIST version requirement because the older  
   version of MIST can cause a script error.  
• Added some additional sound effects in the repo to give users more options.  
   They are separated in two folders: Required and Extras.  
• Now, by default, illumination flares appear over each gate starting and  
   ending at times defined by user. Additional illumination zones are simply  
   added by dropping a trigger zone on the map. Option can be disabled too.  
• Racezones now have a setting for maximum ceiling, allowing aircraft above  
   the zone to fly around without being added to the race.
  
#Legacy .miz with older versions of the script will need to make the following changes:  
  
   • The options settings in the .miz DO SCRIPT are changed to aviation standard  
      units. (feet, knots). See example settings .txt file in the repo for all changes.  
   • Flying backwards through the gates is penalized differently, so just don't do it.  
      This had to be done for new multiple laps feature.  
   • Older miz versions will no longer hear, "You are cleared into the track,  
      smoke on!" voiceover play when a player is added to the course.  
