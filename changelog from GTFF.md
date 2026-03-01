AirRaceScript4  
Changes by GTFreeFlyer, February 2026  
  
• Changed the filename from AirRaceScript3 to AirRaceScript4  
• Many changes as shown below.  Script doubled in size from ~700 lines to  
   nearly 1,400 lines.  
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
• Trigger zone names for racezone, gate, and pylon (formerly pilone) now use  
   dash numbers instead of #001, #002, etc. The automatic naming of items  
   in the editor changed to this behavior a few years ago.  This change allows  
   quick copy/paste of trigger zones.  
• The number of pylon hits required for DNF is now tunable, rather than fixed at 3.  
• Added player speed to intermediate times  
• Added individual settings for the various penalty times  
• Added options for fireworks when a plane crosses the start or finish line
  
Legacy .miz with older versions of the script will need to make the following changes:  
  
   • The options settings in the .miz DO SCRIPT are changed to aviation standard  
      units. (feet, knots). See example settings .txt file in the repo for all changes.  
   • Flying backwards through the gates is penalized differently, so just don't do it.  
      This had to be done for new multiple laps feature.  
   • Older miz versions will no longer hear, "You are cleared into the track,  
      smoke on!" voiceover play when a player is added to the course.  
   • Older miz versions need to rename their pylon trigger zones from  
      "pilone #001" to "pylon-1", etc. for all the zones. No leading zeroes.  
      Same thing applies for gates and racezones, i.e. "gate #001",  
      "racezone #001".  Using the new -1, -2, ... -10 etc. naming allows for  
      quick copy/paste in the editor as the new zones will automatically be named  
      when pasted.