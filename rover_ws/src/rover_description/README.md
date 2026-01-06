To use this package first:

You must have installed firstly:

sudo apt install ros-${ROS_DISTRO}-robot-state-publisher

sudo apt install ros-${ROS_DISTRO}-joint-state-publisher ros-${ROS_DISTRO}-joint-state-publisher-gui

When you have the neccesary packages, you can then:

(remember to soruce /opt/ros/jazzy/setup.bash if you are using bash)

colcon build --packages-select rover_description

source .../KNBMAiR/rover_ws/install/setup.bash

and then finally, you can run the launch file:

ros2 launch rover_description rover_description.launch.py

If it doesnt autocomplete with when mashing TAB, make sure you have sourced ,as described previously.

After launching the file, if you haven't changed it yourself, the joint_state_publisher_gui will appear, in which you can change the rotation of the wheels. If you want to visualize in rviz2 what is going on, you have to do the following:

Open another terminal
Type: 
rviz2

When opened, navigate to the bottom left of rviz2 to a button called ADD
After clicking ADD, in rviz_deafult_pluigns go ahead and add TF and also RobotModel.

To see the links of our robot, you have to select the frame of reference in Global options on top in the left section, then choose base_link. After that you can choose in TF whether or not to show the names of the links etc.

In RobotModel, to see the visual model of the robot, you have to go to the decription topic, and click on the right side of that text (hard to see), till you get the option to choose the topic of RobotModel where you choose /robot_description.
