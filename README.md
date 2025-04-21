# rpiacpi
EDK2 Firmware build to add poe fan capability to Rapsberry Pi UEFI boot


git submodule update --init --recursive


docker build -t edk2-builder .

docker run -it --rm -v $PWD:/workspace edk2-builder bash
