(Most recent items on top)  
-------------------------------------------------------------------------------------  
AirRaceScript4.2  
Changes by GTFreeFlyer, March 10, 2026  

* Added persistence. Your best times are now saved to a file in the same folder as the .miz  
   as long as you desanitize your lua environment. Easily done! Just see the instructions.
* Added inverted gate options where pilot must be inverted with wings level +/- 10 deg  
* Added some more protections against invalid user inputs  
* Added DNF Zones
* Added top 10 racers list to the F10 radio menu
* Added plotting of trail history on F10 map after you finish the race  
* The plotting includes the best race line, always updated when the record is beat  
* Added AutoDraw option which will draw lines on the map between the gates and put labels. 
* The AutoDraw line is replaced with the best race line whenever the record is beat.
* Added two more zone names (fireworks-start-x, and fireworks-end-x) to help control  
   if you want the fireworks to shoot only at the start gate or end gate.
* Approx. 400 more lines of code added since last version 4.1. Since forking this  
   project, it has grown from ~700 lines of code to ~2200. It's packed with features.

-------------------------------------------------------------------------------------  
AirRaceScript4.1  
Changes by GTFreeFlyer, March 5, 2026  

* Added new user option to set distance units as feet or meters  

-------------------------------------------------------------------------------------  
AirRaceScript4  
Changes by GTFreeFlyer, February 2026   
  
* Changed the filename from AirRaceScript3 to AirRaceScript4  
* Many changes and additions!  Script more than doubled in size from ~700 lines to  
   nearly 1,800 lines.  
* Crashed racers are not removed from race, preventing further racing - FIXED  
* Added option to override global gate height and global bonus gate height, PER gate!  
   This means you can easily set a custom height and bonus height for each gate, if  
   desired.  Great for bridges, buildings, etc.  
* Readme updated - major overhaul. Example settings file and suggested .miz breifing text  
   files added to root folder in repo.  
* Added auto-counting of triggerzones which now eliminates the required settings for that.  
* Added capability to have multiple laps. NumberLaps can be set in the  
   editor without touching the lua script.  
* Added options for group races, instead of individual timers so the  
   timer starts for everyone when the first plane enters gate-1.  
* Updated note about minimum MIST version requirement because the older  
   version of MIST can cause a script error.  
* Added some additional sound effects in the repo to give users more options.  
   They are separated in two subfolders: Required and Extras.  
* Now, by default, illumination flares appear over each gate starting and  
   ending at times defined by user. Additional illumination zones are simply  
   added by dropping a trigger zone on the map. Option can be disabled too.  
* Racezones now have a setting for maximum ceiling, allowing aircraft above  
   the zone to fly around without being added to the race.  
* Trigger zone names for racezone, gate, and pylon (formerly pilone) now use  
   dash numbers instead of #001, #002, etc. The automatic naming of items  
   in the editor changed to this behavior a few years ago.  This change allows  
   quick copy/paste of trigger zones.  
* The number of pylon hits required for DNF is now tunable, rather than fixed at 3.  
* Added players' speeds to intermediate times displayed in the outText  
* Added individual settings for the various penalty times  
* Added options for fireworks when a plane crosses the start or finish line.  
* Users can now adjust the individual penalty times, as well as the bonus time.  
    
Legacy .miz with older versions of the script will need to make the following changes  
if you would like to use the newest version of the script:  
  
   * The options settings in the .miz DO SCRIPT are changed to aviation standard  
      units. (feet, knots). See example settings .txt file in the repo for all changes.  
   * Flying backwards through the gates is penalized differently, so just don't do it.  
      This had to be done for new multiple laps feature.  
   * Older miz versions will no longer hear, "You are cleared into the track,  
      smoke on!" voiceover play when a player is added to the course.  
   * Older miz versions need to rename their pylon trigger zones from  
      "pilone #001" to "pylon-1", etc. for all the zones. No leading zeroes.  
      Same thing applies for gates and racezones, i.e. "gate #001",  
      "racezone #001".  Using the new -1, -2, ... -10 etc. naming allows for  
      quick copy/paste in the editor as the new zones will automatically be named  
      when pasted.