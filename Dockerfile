FROM ubuntu:16.04

# Install build & basic dependencies
RUN apt-get -y update && apt-get install -y sudo build-essential cmake vim wget git software-properties-common

# Install Octave 4 & packages
RUN apt-add-repository ppa:octave/stable && apt-get update && \
	apt-get install -y octave liboctave-dev zip && \
    echo "pkg install -forge -auto image" | octave --no-window-system && \
    echo "pkg install -forge -auto io" | octave --no-window-system && \
    echo "pkg install -forge -auto statistics" | octave --no-window-system

ENV TOOLKIT_ROOT /usr/local/toolkit

# Add toolkit source
ADD . /usr/local/toolkit/

# Compile native components
RUN mkdir -p /usr/local/toolkit/native && \
	echo "addpath ('${TOOLKIT_ROOT}'); toolkit_path; workspace_load('OnlyDefaults', true); initialize_native; " | octave --no-window-system

# Compile TraX
RUN cd ${TOOLKIT_ROOT}/native/trax && mkdir build && cd build \
     && cmake -DBUILD_CLIENT=ON -DBUILD_MATLAB=ON .. && make  && make install && cd .. && rm -rf build

# Set environment variables.
ENV USER vot
ENV HOME /home/$USER

# Create new user
RUN \
  useradd -m $USER && \
  mkdir -m 440 -p /etc/sudoers.d/ && \
  echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER

# Define user name.
USER $USER

RUN echo "addpath ('/toolkit');" >> ~/.octaverc && mkdir -p /home/$USER/workspace

WORKDIR /home/$USER/workspace

# Define default command.
CMD ["/bin/bash"]

