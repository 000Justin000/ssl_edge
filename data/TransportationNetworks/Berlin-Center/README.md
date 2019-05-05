# Berlin Center Network

## Source  
Provided by Rolf Möhring (TU Berlin) Andreas Schulz (MIT), and Nicolas Stier-Moses (Columbia University) with the assistance of Stefan Gnutzmann (DaimlerChrysler). These networks were used, among other things, in the paper by O. Jahn, R.H. Möhring, A.S. Schulz, and N. Stier-Moses titled "System-Optimal Routing of Traffic Flows with User Constraints in Networks with Congestion" (Operations Research, 53:4, 600-616, 2005). The original format of these files is slightly different from the other networks, and it is described in the readme file included in the packet.
 
TNTP version prepared by Hillel Bar-Gera.

Via: [http://www.bgu.ac.il/~bargera/tntp/](http://www.bgu.ac.il/~bargera/tntp/)  

## Scenario


## Contents

 - `berlin-center_net.tntp` Network  
 - `berlin-center_trips.tntp` Demand  
 - `berlin-center_node.tntp`  Node Coordinates  
 - `berlin-center_Node-Conversion.txt` 

## Dimensions  
Zones: 865  
Nodes: 12,981  
Links: 28,376  
Trips: 168222.301999998980000  

## Units
Time:
Distance: 
Speed: 
Cost: 

## Generalized Cost Weights
Toll: 
Distance: 

## Solutions

## Issues  
Hong Zheng identified the following duplicate links in the Berlin Center network: [1246, 1244]; [3644, 3643]; [7773, 7870]; [7777, 7779]; [8468, 8472]; [8472, 8468]. Notice that the parameters of the duplicate links are not the same. Any reports using this network until 2012 should be assumed to rely on the network with the duplicated links. Any reports using this network from 2013 onwards should be assumed to rely on the network with the first link in each duplicated pair.
