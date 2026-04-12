pkill -9 run_datanode
pkill -9 run_proxy

./project/cmake/build/run_datanode 10.10.1.6:17600 & 
./project/cmake/build/run_datanode 10.10.1.6:17601 & 
./project/cmake/build/run_datanode 10.10.1.6:17602 & 
./project/cmake/build/run_datanode 10.10.1.6:17603 & 
./project/cmake/build/run_datanode 10.10.1.6:17604 & 
./project/cmake/build/run_datanode 10.10.1.6:17605 & 
./project/cmake/build/run_datanode 10.10.1.6:17606 & 
./project/cmake/build/run_datanode 10.10.1.6:17607 & 

sleep 5s

./project/cmake/build/run_proxy 10.10.1.6:50405  & 

