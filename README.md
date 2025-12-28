# KNBMAiR


watch https://www.youtube.com/watch?v=V_C8Cmv4fgk to learn how to turn on the rover_description.urdf

All neccesary info regarding the usage of this workspace will be listed in this readme


To get the code we have here, just simply do

git clone -b feat/rover_description and_the_url_you_get_from_github_of_this_repository

ESSENTIAL TO SPECIFY THE BRANCH.

After that, you get your repository and can start sourcing files.


Firstly, do:

source /opt/ros/jazzy/setup.bash (if you are not using another interpreter such as ex. .zh)

then do:

colcon build (at the rover_ws level)

then do:

source install/setup.bash (from the rower_ws level)

AFTER THAT YOU SHOULD BE READY TO DO THE BIG BOY STUFF.

there is this thing called a launch file we will be using to by pass the magic required to do to start the model of the rover. It uses the state publisher and other shabang from the video.

We do:

ros2 launch rover_description rover_description.launch.py

It sohuld be autocompleting if you do TAB when writing the command. If it doesnt see rover_description and rover_description.lunch.py, then you probably didnt source it correclty and the interpreter doesnt see the files. Do the previous steps again, maybe randomize the order till it works for you :))
