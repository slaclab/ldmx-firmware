source /afs/slac.stanford.edu/g/reseng/xilinx/2022.2/Vivado/2022.2/settings64.sh  
source /afs/slac.stanford.edu/g/reseng/synopsys/vcs/T-2022.06-SP2/settings.sh

if [ ! "$(ldconfig -p | grep zmq)" ]; then
    source /afs/slac.stanford.edu/g/reseng/zeromq/4.2.0/settings.sh
fi
