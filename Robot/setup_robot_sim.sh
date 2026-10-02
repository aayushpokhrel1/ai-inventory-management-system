#!/usr/bin/env bash
# =============================================================================
# Senior-Design robot simulation setup for WSL Ubuntu 24.04 (ROS2 Jazzy + Gazebo Harmonic)
# Run this INSIDE your WSL Ubuntu terminal, from anywhere:
#   bash Robot/setup_robot_sim.sh
# You will be asked for your sudo password once.
# =============================================================================
set -e

WS="$HOME/twak_ws"
# The repo root is derived from this script's own location (it lives in Robot/),
# so it works wherever the checkout is, including through /mnt/c on the Windows
# side (slower but works). Override with SENIOR_REPO=/path if needed.
REPO_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${SENIOR_REPO:-$REPO_DEFAULT}"

echo "==> Using repo at: $REPO"
if [ ! -d "$REPO/Robot/twakbot" ]; then
  echo "!! Robot/twakbot not found under $REPO"
  echo "   Run this script from inside a checkout, e.g.:"
  echo "     git clone https://github.com/aayushpokhrel1/ai-inventory-management-system.git"
  echo "     bash ai-inventory-management-system/Robot/setup_robot_sim.sh"
  exit 1
fi

# ---- 1. ROS2 Jazzy apt repo --------------------------------------------------
echo "==> Adding ROS2 Jazzy apt repository"
sudo apt update
sudo apt install -y software-properties-common curl gnupg lsb-release
sudo add-apt-repository -y universe
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
  -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
  | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
sudo apt update

# ---- 2. Core ROS2 + simulation stack ----------------------------------------
echo "==> Installing ROS2 Jazzy desktop + Gazebo Harmonic + Nav2 + control stack"
sudo apt install -y \
  ros-jazzy-desktop \
  ros-jazzy-ros-gz \
  ros-jazzy-ros2-control ros-jazzy-ros2-controllers ros-jazzy-gz-ros2-control \
  ros-jazzy-twist-mux ros-jazzy-joint-state-publisher-gui \
  ros-jazzy-xacro \
  ros-jazzy-slam-toolbox \
  ros-jazzy-navigation2 ros-jazzy-nav2-bringup \
  python3-colcon-common-extensions python3-rosdep

# ---- 3. Python deps for YOLO object detection (aisle_counter.py) -------------
echo "==> Installing YOLO / OpenCV python deps"
sudo apt install -y python3-pip
pip install --break-system-packages ultralytics opencv-python numpy

# ---- 4. Build the colcon workspace ------------------------------------------
echo "==> Creating workspace at $WS"
mkdir -p "$WS/src"
cp -r "$REPO/Robot/twakbot"        "$WS/src/"
cp -r "$REPO/Robot/nav_waypoints"  "$WS/src/"

# ---- 5. Fix the hardcoded world mesh path -----------------------------------
# The committed world references /home/sabal/... which does not exist here, and the
# .dae warehouse mesh was never committed (only the .blend). We repoint the path so
# Gazebo doesn't error; if the mesh is absent the world simply loads empty ground.
WORLD="$WS/src/twakbot/worlds/blender_world.world"
NEWMESH="$WS/src/twakbot/worlds/my_scene/meshes/dae/inventory_world.dae"
echo "==> Patching world mesh path in $WORLD"
sed -i "s|file:///home/sabal/ROBOTICS/twak_ws/src/twakbot/worlds/my_scene/meshes/dae/inventory_world.dae|file://$NEWMESH|g" "$WORLD"
if [ ! -f "$NEWMESH" ]; then
  echo "   NOTE: warehouse mesh $NEWMESH is missing (not in repo)."
  echo "   The sim will run with an EMPTY world. To get the warehouse scene, export"
  echo "   Robot/twakbot/assets/mainfile_environmentonly.blend to Collada (.dae) at that path:"
  echo "     blender -b <that.blend> --python-expr \"import bpy; bpy.ops.wm.collada_export(filepath='$NEWMESH')\""
fi

source /opt/ros/jazzy/setup.bash
echo "==> Building workspace (colcon)"
cd "$WS"
colcon build --symlink-install
echo "==> Build complete."

# ---- 6. How to run ----------------------------------------------------------
cat <<EOF

=============================================================================
 DONE. To launch the simulation (each in its own WSL terminal):

  # Terminal A - Gazebo + robot + controllers + bridge
  source /opt/ros/jazzy/setup.bash
  source $WS/install/setup.bash
  ros2 launch twakbot launch_sim.launch.py

  # Terminal B - RViz visualization
  source /opt/ros/jazzy/setup.bash
  source $WS/install/setup.bash
  rviz2 -d $WS/src/twakbot/config/main.rviz

  # Terminal C (optional) - SLAM mapping
  ros2 launch twakbot online_async_launch.py use_sim_time:=true

  # Terminal D (optional) - Nav2 + waypoint navigation
  ros2 launch twakbot navigation_launch.py use_sim_time:=true
  ros2 run nav_waypoints nav_waypoint_runner

 If Gazebo shows a black window under WSLg, force software GL:
    export LIBGL_ALWAYS_SOFTWARE=1     # then relaunch Terminal A
=============================================================================
EOF
