from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue
from launch.substitutions import LaunchConfiguration, Command, PathJoinSubstitution, PythonExpression
from ament_index_python.packages import get_package_share_directory

def generate_launch_description():
    pkg_share = get_package_share_directory('rover_description')

    model_arg = DeclareLaunchArgument(
        'model',
        default_value=PathJoinSubstitution([pkg_share, 'urdf', 'rover_description.urdf.xacro']),
        description='Path to the .xacro file'
    )

    use_gui_arg = DeclareLaunchArgument(
        'use_gui',
        default_value='True',
        description='true -> joint_state_publisher_gui, false -> joint_state_publisher'
    )

    robot_description = ParameterValue(
        Command(['xacro ', LaunchConfiguration('model')]),
        value_type=str
    )

    rsp = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        parameters=[{'robot_description': robot_description}],
        output='screen'
    )

    jsp_gui = Node(
        condition=IfCondition(LaunchConfiguration('use_gui')),
        package='joint_state_publisher_gui',
        executable='joint_state_publisher_gui',
        output='screen'
    )

    jsp = Node(
        condition=IfCondition(PythonExpression(['not ', LaunchConfiguration('use_gui')])),
        package='joint_state_publisher',
        executable='joint_state_publisher',
        output='screen'
    )

    return LaunchDescription([model_arg, use_gui_arg, rsp, jsp_gui, jsp])
