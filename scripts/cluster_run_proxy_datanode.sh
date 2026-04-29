pkill -9 run_datanode
pkill -9 run_proxy

./project/cmake/build/run_datanode 10.10.1.20:17600 & 
./project/cmake/build/run_datanode 10.10.1.20:17601 & 
./project/cmake/build/run_datanode 10.10.1.20:17602 & 
./project/cmake/build/run_datanode 10.10.1.20:17603 & 
./project/cmake/build/run_datanode 10.10.1.20:17604 & 
./project/cmake/build/run_datanode 10.10.1.20:17605 & 
./project/cmake/build/run_datanode 10.10.1.20:17606 & 
./project/cmake/build/run_datanode 10.10.1.20:17607 & 
./project/cmake/build/run_datanode 10.10.1.20:17608 & 
./project/cmake/build/run_datanode 10.10.1.20:17609 & 
./project/cmake/build/run_datanode 10.10.1.20:17610 & 
./project/cmake/build/run_datanode 10.10.1.20:17611 & 
./project/cmake/build/run_datanode 10.10.1.20:17612 & 
./project/cmake/build/run_datanode 10.10.1.20:17613 & 
./project/cmake/build/run_datanode 10.10.1.20:17614 & 
./project/cmake/build/run_datanode 10.10.1.20:17615 & 
./project/cmake/build/run_datanode 10.10.1.20:17616 & 
./project/cmake/build/run_datanode 10.10.1.20:17617 & 
./project/cmake/build/run_datanode 10.10.1.20:17618 & 
./project/cmake/build/run_datanode 10.10.1.20:17619 & 
./project/cmake/build/run_datanode 10.10.1.20:17620 & 
./project/cmake/build/run_datanode 10.10.1.20:17621 & 
./project/cmake/build/run_datanode 10.10.1.20:17622 & 
./project/cmake/build/run_datanode 10.10.1.20:17623 & 
./project/cmake/build/run_datanode 10.10.1.20:17624 & 
./project/cmake/build/run_datanode 10.10.1.20:17625 & 
./project/cmake/build/run_datanode 10.10.1.20:17626 & 
./project/cmake/build/run_datanode 10.10.1.20:17627 & 
./project/cmake/build/run_datanode 10.10.1.20:17628 & 
./project/cmake/build/run_datanode 10.10.1.20:17629 & 

./project/cmake/build/run_proxy 10.10.1.20:50405 10.10.1.2 & 

