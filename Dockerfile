ARG ROS_DISTRO=jazzy
ARG BASE_IMAGE=ros:${ROS_DISTRO}-ros-base
FROM $BASE_IMAGE

RUN apt-get update && apt-get install -y --no-install-recommends ros-dev-tools

RUN mkdir -p /rmf_traffic_editor_ws/src
WORKDIR /rmf_traffic_editor_ws
RUN rosdep update --rosdistro ${ROS_DISTRO}

ENV DEBIAN_FRONTEND=noninteractive
# 2. CACHE DEPENDENCIES: Copy ONLY package.xml files first
COPY rmf_building_map_tools/package.xml src/rmf_building_map_tools/package.xml
COPY rmf_traffic_editor/package.xml src/rmf_traffic_editor/package.xml
COPY rmf_traffic_editor_assets/package.xml src/rmf_traffic_editor_assets/package.xml
COPY rmf_traffic_editor_test_maps/package.xml src/rmf_traffic_editor_test_maps/package.xml

# 3. Install ROS dependencies (Expensive, but now cached!)
RUN rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -yr \
    && rm -rf /var/lib/apt/lists/*

# 4. COPY actual source code (Changes frequently)
COPY rmf_building_map_tools src/rmf_building_map_tools
COPY rmf_traffic_editor src/rmf_traffic_editor
COPY rmf_traffic_editor_assets src/rmf_traffic_editor_assets
COPY rmf_traffic_editor_test_maps src/rmf_traffic_editor_test_maps

# Compile ROS 2 packages via colcon
RUN . /opt/ros/${ROS_DISTRO}/setup.sh \
  && colcon build --cmake-args -DCMAKE_BUILD_TYPE=Release

# Clean up to minimize memory space.
RUN rm -rf build log src \
  && sed -i '$isource "/rmf_traffic_editor_ws/install/setup.bash"' /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
