# Colosseum Near-Real-Time RIC

This is a part of the [OpenRAN Gym](https://openrangym.com) project. It is minimal version of the O-RAN Software Community near-real-time RIC (Bronze release) adapted and extended to work on the [Colosseum](https://www.colosseum.net/) wireless network emulator.
The scripts in this repository will start a minimal near-real-time RIC in the form of Docker containers (namely, `db`, `e2mgr`, `e2rtmansim`, `e2term`).
The repository also features a sample xApp, which connects to the [SCOPE](https://github.com/wineslab/colosseum-scope) RAN environment through the following [E2 termination](https://github.com/wineslab/colosseum-scope-e2).

If you use this software, please reference the following paper: 

> M. Polese, L. Bonati, S. D'Oro, S. Basagni, T. Melodia, "ColoRAN: Design and Testing of Open RAN Intelligence on Large-scale Experimental Platforms," arXiv 2112.09559 [cs.NI], December 2021. [bibtex](https://ece.northeastern.edu/wineslab/wines_bibtex/polese2021coloran.txt) [pdf](https://arxiv.org/pdf/2112.09559.pdf)

This work was partially supported by the U.S. National Science Foundation under Grants CNS-1923789 and NSF CNS-1925601, and the U.S. Office of Naval Research under Grant N00014-20-1-2132.

## Structure

This repository is organized as follows

```
/colosseum-near-rt-ric 
|
└──build-ns-o-ran.sh
|
└──setup-scripts
|   |
|   └──import-wines-images.sh
|   |
|   └──setup-ric-bronze.sh
|   |
|   └──start-xapp-ns-o-ran.sh
|   |
└──setup
|  |
|  └──dbaas
|  |
|  └──e2
|  |
|  └──sample-xapp
|  |
|  └──xapp-sm-connector
```

## Setup Environment

**======================================**

**Make sure Docker is installed first**

**======================================**

1. Clone the repository.
```bash
cd ~
git clone https://github.com/den-dimas/colosseum-near-rt-ric.git -b ns-o-ran colosseum-near-rt-ric
```

2. Import docker images.
```bash
cd ~/colosseum-near-rt-ric/setup-scripts
./import-wines-images.sh
```

3. Setup RIC Containers.
```bash
cd ~/colosseum-near-rt-ric/setup-scripts
./setup-ric-bronze.sh
```

4. Deploy ns-o-ran to Docker
```bash
cd ~/colosseum-near-rt-ric/
./build-ns-o-ran.sh
```

## Running the bw-xapp

This repository is forked from the original Colosseum Near RT RIC Github. I've changed the routing to also support kpimon xApp to be deployed in the environment. I also modified the Dockerfile for building the ns-o-ran which were outdated in the original repository.

I've also changed the `sample-xapp` to `bw-xapp` to retrieve KPM information from SDL (**dummy**) and sends RIC Control Message based on the KPM information. It involves extending the `xapp-sm-connector` message handler to send and receive the KPM data and the created strategy in the `bw-xapp` xApp.

To deploy and run the `bw-xapp` to the enviroment:
```bash
cd ~/colosseum-near-rt-ric/setup-scripts
./start-xapp-ns-o-ran.sh
```

## System Overview

The way the `bw-xapp` works is quite simple. The `bw-xapp` itself is just an abstraction from the `xapp-sm-connector`. The `xapp-sm-connector` is actually a modified and extended version of the RIC App HW ([Github](https://github.com/o-ran-sc/ric-app-hw.git)),

The `ric-app-hw` is modified so that it can open a communication channel via a socket. This way, the `bw-xapp` need only to send to that socket in order to send a message to the E2Term. The encoding and decoding of the E2SM & E2AP message is done by the `xapp-sm-connector`.

The routing of the environment can be found in the `setup-scripts/setup-ric-bronze.sh` script:
```sh
ROUTERFILE=`pwd`/router.txt
cat << EOF > $ROUTERFILE
newrt|start
rte|10020|$E2MGR_IP:3801
rte|10060|$E2TERM_IP:38000
rte|10061|$E2MGR_IP:3801
rte|10062|$E2MGR_IP:3801
rte|10070|$E2MGR_IP:3801
rte|10071|$E2MGR_IP:3801
rte|10080|$E2MGR_IP:3801
rte|10081|$E2TERM_IP:38000
rte|10082|$E2TERM_IP:38000
rte|10360|$E2TERM_IP:38000
rte|10361|$E2MGR_IP:3801
rte|10362|$E2MGR_IP:3801
rte|10370|$E2MGR_IP:3801
rte|10371|$E2TERM_IP:38000
rte|10372|$E2TERM_IP:38000
rte|1080|$E2MGR_IP:3801
rte|1090|$E2TERM_IP:38000
rte|1100|$E2MGR_IP:3801
rte|12010|$E2MGR_IP:38010
rte|1101|$E2TERM_IP:38000
rte|12002|$E2TERM_IP:38000
rte|12003|$E2TERM_IP:38000
rte|10091|$E2MGR_IP:4801
rte|10092|$E2MGR_IP:4801
rte|1101|$E2TERM_IP:38000
rte|1102|$E2MGR_IP:3801
rte|12001|$E2MGR_IP:3801
rte|12011|10.0.2.25:4560      |
rte|12012|10.0.2.25:4560      |
rte|12021|10.0.2.25:4560      | ---> Is for kpimon xApp message
rte|12022|10.0.2.25:4560      | ---> type routing
rte|12030|10.0.2.25:4560      |
rte|12050|10.0.2.25:4560      |
mse|12060|24|10.0.2.24:4560   | ---> is for bw-xapp RIC Indication
newrt|end
EOF
```

## Testing the System

To test and try the system, you can do it without deploying the kpimon xApp first since the integration has not been implemented yet. However, if you want to try the kpimon too, you can see the repository: [kpimon Github](https://github.com/den-dimas/ric-app-kpimon.git).

1. Open two terminal A & B
2. Terminal A:
```bash
docker exec -it ns-o-ran /bin/bash
cd ns3-mmwave-oran/
./ns3 run scratch/scenario-zero.cc
```
3. Terminal B:
```bash
docker exec -it bw-xapp-24 /bin/bash
/home/bw-xapp/run_xapp.sh
```
