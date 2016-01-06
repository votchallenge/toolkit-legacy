FROM ubuntu:14.04

# Install build & basic dependencies
RUN apt-get -y update
RUN apt-get install -y build-essential cmake vim wget git

# Install Octave 4.0 & packages
RUN sudo apt-get update
RUN apt-get install -y software-properties-common
RUN sudo apt-add-repository ppa:octave/stable
RUN sudo apt-get update
RUN sudo apt-get install -y octave liboctave-dev zip
RUN echo "pkg install -forge -auto image" | octave
RUN echo "pkg install -forge -auto io" | octave
RUN echo "pkg install -forge -auto statistics" | octave

# Add VOT-toolkit
ADD . /vot-toolkit
RUN echo "addpath ('/vot-toolkit');" >> ~/.octaverc

# Setup test Workspace & downloads TraX precompiled files
WORKDIR /test_workspace
# (This is hackish. We should have a script to do this without user input)
RUN (echo "toolkit_path;set_global_variable('native_download',false);workspace_create"; \
     echo 1; echo test; echo N) | octave
# Compile Trax
RUN cd /vot-toolkit/native/trax && mkdir build && cd build \
     && cmake .. && make  && make install

# Define default command.
CMD ["/bin/bash"]
