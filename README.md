This script is for DCS (digital combat simulator) mission creators.   
It allows to set up an air race track with little effort.  
-----  
The script will be part of the mission file (.miz) you create. It will track   
timing and violations of the participating pilots.  
-----  
All you need to do is:
1. Set up the gates: place single or pairs of pylons along the race track.   
   You may use any object. Static objects work best for performance.  
   The track may or may not end where it starts, thus being linear or circular.  
2. Surround each pylon with a trigger zone and name them "pilone #001", "pilone #002", ...  
3. Add a trigger zone to each gate, spanning exactly between pairs of pylons. Name those "gate #001",  
   "gate #002", ...  
   These trigger zones mark where pilots have to fly through in order to pass a gate.  
   You only need one gate near each pylon, regardless of the number of laps.    
4. Create one or more trigger zones covering the entire race track, allowing to detect if   
   participants entered or left the race track.   
   Name them "racezone #001", "racezone #002", ...  
5. If you wish to race at night, illumination flares are provided by default above each gate, and 
   above any other zone named "illum-1", "illum-2", etc.  They will respawn every 5 minutes.  
   Feature added by GTFreeFlyer.  
   Don't use leading zeroes for the numbers. Example: illum-9, illum-10, illum-132). This allows  
   quick copy/paste of trigger zone in the editor.  
   See the setup instructions in the comment block at the start of the script for all illumination 
   options and settings.  
6. Create three script triggers to initialize and run this script. See the comment block at the 
   start of the script.  
7. Add a dummy trigger that plays all required sound files. This makes sure, they are added   
   to the mission file. You can use a trigger condition that will never be true.  
8. Add a detailed breifing so that players know what to do. Use can use suggestedMizBriefing.txt as  
   a template.   
-----  
For Group Races Only...:  

(Everyone enters the race together and shares the same start time. Can optionally use a pace plane)  
(Group race feature (all items below), and capability for multiple laps, added by GTFreeFlyer)  

• If you are running a group race, you will need to set the option for GroupRace = true (see 
   instructions in script)    

• In the .miz, I suggest you add an AI pace plane for everyone to follow into the start gate.  This  
   is the easiest way to coordinate a group of people, but is not required.  

• If using a pace plane, you MUST create a trigger that will execute as soon as the pace drops into  
   the race and tells the racers, "Race on!" (or whatever).  The trigger must be "Flag On" with the  
   flag named "PaceDrop". This is what will trigger race eligibility and a line-up check to make sure  
   no one is cheating. You'll either be kicked out of the race if you are way off parameters, or incur  
   penalites.  
   The parameters, at the time of drop-in, are as follows relative to the pace plane:  
      -----You must be within 1 nautical mile  
      -----You must not be greater than 40 meters ahead of the pace. (0-40m will incur penalty time)  
      -----You altitide must be within +100/-500 feet (0 to +100 feet with incur penalty time)  
      -----You must be on the right side of the pace (everyone right-line-abreast formation)  

• Also if using a pace plane, you MUST set its name in the mission start trigger with race settings.  

• Only for group races, the default behavior is that the script will load, but NOT run.  You must  
   create a trigger to run it.  See next bullet point.  

• Create a switched condition trigger zone ahead of where the pace plane will drop-in, such that the  
   AI pace plane will fly through it in order to start the race script and detect nearby players.   
   The action needs to be DO SCRIPT, and type startRaceScript() into the text box. Of course, you may  
   start the script at any other time if it makes more sense for you.  

• When everyone has completed the race, the script will stop running 15 seconds later. Next time your  
   pace flies through the zone mentioned above, the script will start again.  

• If desired, you may start and stop the script at any time using DO SCRIPT trigger with   
     startRaceScript() or stopRaceScript() typed into the text box.  

• The script provides general-purpose flags that you may use to trigger your own stuff in the miz:   
   GroupRaceStarted (Toggles true when the first racer enters the first gate.)  
   GroupRaceFinished (Toggles true about 15 seconds after the last racer has finished the race, or if  
      there are no more racers remaining due to crashes, disconnects, etc)  
   FinishLineCrossed (Toggles true when the first racer crosses the finish line.)  
   Lap1Gate1Reached, Lap1Gate2Reached ... Lap3Gate15Reached, etc. (Toggles true at the first occurrence  
      of each gate hit. All will reset back to false at the beginning of a race when the timer starts)   
   Use these as read-only (don't change them on your own).  
   All of them will be value 0 or 1 in the lua script, which is the same thing as false or true, and  
   off or on, in DCS. i.e. "Flag On" is the same thing as "Flag is true", and also the same thing as  
   "Flag value = 1"  
   
• Contact GTFreeFlyer (Discord or ED Forums) with any questions regarding group races. The best thing is to  
   check out the included example, "GTFreeFlyers Marianas WWII Races.miz", to see how things are set up.  

Source: https://forums.eagle.ru/showthread.php?t=120234  

Example missions:  
• 04_celebrate.miz (requires Persian Gulf map)  
• GTFreeFlyers Marianas WWII Races.miz (group race with pace plane. warbirds. wwii assets req'd)  
