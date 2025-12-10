Be aware that you need to follow step 1-3! The python script WILL EXECUTE GIT CHECKOUT COMMANDS. This WILL remove all changes you've done, if you dont clone finamp again.


This script is also meant be running on linux :)


1. Make a new Temporary folder somewhere else (not in the finamp repo)  
    `cd ~ && mkdir Temporary && cd Temporary`
2. Clone finamp into there  
    `git clone https://github.com/jmshrv/finamp && cd finamp` 
3. Switch to the redesign branch  
    `git checkout redesign`
4. Download the [gitstat executable](https://github.com/nielskrijger/gitstat/tree/master?tab=readme-ov-file#how-to-use) and place the extracted executable into the `Temporary` folder
5. copy `./tools/code_recap/recap.py` to `Temporary`
6. run `./gitstat ./finamp`
7. Wait ~40minutes for gitstat to finish
8. After that a json should appear 
9. Run `python3 ./recap.py ./gitstat_result.json`
10. Done (you can now delete the `Temporary` Folder if you like)


