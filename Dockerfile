FROM ros:humble

ENV AGENTIC_PACKAGE=agentic_ros
ENV AGENTIC_NODE=agentic_ros_node
ENV CONFIG_PATH="/home/agentic/config"

USER root
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
# install ros package
RUN apt-get update && apt-get install -y \
  ros-humble-demo-nodes-cpp curl wget python3.11-dev \
  swig gpiod libgpiod-dev \
  virtualenv nano qt5-* \
  ros-humble-demo-nodes-py && \
  rm -rf /var/lib/apt/lists/*


RUN useradd -m agentic

USER agentic

WORKDIR /home/agentic
COPY ./run.sh /home/agentic/run.sh
COPY ./prefill-test /home/agentic/prefill-test

# create ROS workspace and virutal env
RUN mkdir -p /home/agentic/ros2_ws/src
COPY ./requirements.txt /home/agentic/ros2_ws/requirements.txt
COPY ./run-ros-*.sh /home/agentic/ros2_ws/
COPY ./config /home/agentic/config
RUN cd /home/agentic/ros2_ws && virtualenv -p python3.10 ./venv && touch ./venv/COLCON_IGNORE


# activate venv and install dependencies
RUN source /opt/ros/humble/setup.bash && source /home/agentic/ros2_ws/venv/bin/activate && pip install -r /home/agentic/ros2_ws/requirements.txt


USER root
RUN chmod -R g+r /home/agentic
RUN chown -R agentic:agentic /home/agentic
# install VS Code (code-server)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# create ROS packages
USER agentic
RUN cd ~/ros2_ws/src && source /opt/ros/humble/setup.bash && ros2 pkg create --build-type ament_python --dependencies rclpy std_msgs --license Apache-2.0 rel_ros_master_control
RUN cd ~/ros2_ws/src && source /opt/ros/humble/setup.bash && ros2 pkg create --build-type ament_python --dependencies rclpy std_msgs --license Apache-2.0 agentic_ros
RUN cd ~/ros2_ws/src && source /opt/ros/humble/setup.bash && ros2 pkg create --build-type ament_cmake --license Apache-2.0 rel_interfaces
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "source /home/agentic/ros2_ws/venv/bin/activate" >> ~/.bashrc
RUN echo 'export USE_TEST_MODBUS="true"' >> ~/.bashrc
RUN echo 'export LOGLEVEL="DEBUG"' >> ~/.bashrc
RUN echo 'export APP_MASTER_IOLINK_ID=0' >> ~/.bashrc

ENV PYTHONPATH=""
ENV PYTHONPATH="${PYTHONPATH}:/home/agentic/ros2_ws/venv/lib/python3.10/site-packages"
ENV PYTHONPATH="${PYTHONPATH}:/home/agentic/ros2_ws/src/agentic_ros"
ENV PYTHONPATH="${PYTHONPATH}:/home/agentic/ros2_ws/src/rel_ros_master_control"


# launch ros package
CMD ["/home/agentic/run.sh"]
