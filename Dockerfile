FROM ros:humble

ENV AGENTIC_PACKAGE=agent_ros_collab
ENV AGENTIC_NODE=agent_ros_collab_node
ENV CONFIG_PATH="/home/agentic/config"

USER root
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
# install ros package
RUN apt-get update && apt-get install -y \
  ros-humble-demo-nodes-cpp curl wget python3.12 python3.12-dev
  swig gpiod libgpiod-dev \
  virtualenv nano qt5-* \
  ros-humble-demo-nodes-py && \
  rm -rf /var/lib/apt/lists/*


RUN useradd -m agentic

USER agentic

WORKDIR /home/agentic
COPY ./run.sh /home/agentic/run.sh

# create ROS workspace and virutal env
RUN mkdir -p /home/agentic/ros2_ws/src
COPY ./requirements.txt /home/agentic/ros2_ws/requirements.txt
COPY ./run-ros-*.sh /home/agentic/ros2_ws/
COPY ./config /home/agentic/config
RUN cd /home/agentic/ros2_ws && virtualenv -p python3.12 ./venv && touch ./venv/COLCON_IGNORE


# activate venv and install dependencies
RUN source /opt/ros/humble/setup.bash && source /home/agentic/ros2_ws/venv/bin/activate && pip install -r /home/agentic/ros2_ws/requirements.txt


USER root
RUN usermod -a -G dialout agentic
RUN chmod -R g+r /home/agentic
RUN chown -R agentic:agentic /home/agentic
# install VS Code (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# create ROS packages
USER agentic
RUN cd ~/ros2_ws/src && source /opt/ros/humble/setup.bash && ros2 pkg create --build-type ament_python --dependencies rclpy std_msgs --license Apache-2.0 agent_ros_orchestrator
#RUN cd ~/ros2_ws/src && source /opt/ros/humble/setup.bash && ros2 pkg create --build-type ament_python --dependencies rclpy std_msgs --license Apache-2.0 agent_ros_collab
RUN cd ~/ros2_ws/src && source /opt/ros/humble/setup.bash && ros2 pkg create --build-type ament_cmake --license Apache-2.0 agentic_interfaces
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "source /home/agentic/ros2_ws/venv/bin/activate" >> ~/.bashrc
RUN echo 'export LOGLEVEL="DEBUG"' >> ~/.bashrc

ENV PYTHONPATH=""
ENV PYTHONPATH="${PYTHONPATH}:/home/agentic/ros2_ws/venv/lib/python3.12/site-packages"
#ENV PYTHONPATH="${PYTHONPATH}:/home/agentic/ros2_ws/src/agent_ros_collab"
ENV PYTHONPATH="${PYTHONPATH}:/home/agentic/ros2_ws/src/agent_ros_orchestrator"


# launch ros package
CMD ["/home/agentic/run.sh"]
