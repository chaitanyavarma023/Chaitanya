
# To build the container

USER=$1 ; if [ -z "$USER" ]; then echo "Please give your system username as arguement."; exit 1; fi

exit
docker build . -t bob-the-builder --compress --build-arg user=$USER --build-arg uid=$(id -u) --build-arg gid=$(id -g)

# To run

docker run --name=bob-the-builder -it \
    -v /home/$USER/.gitconfig:/home/$USER/.gitconfig:ro \
    -v $(pwd):/home/$USER/workdir \
    -v /home/$USER/.ssh:/home/$USER/.ssh/:ro \ 
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /home/$USER/key:/home/$USER/key:ro \ 
    bob-the-builder
