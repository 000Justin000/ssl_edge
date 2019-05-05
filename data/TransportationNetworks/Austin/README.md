# Austin Network

## Source
This 2005 dataset was kindly provided by Chi Xie.  
Via: http://www.bgu.ac.il/~bargera/tntp/

## Scenario
FIXME
2005 Peak-Hour

## Contents

 - `Austin_net.tntp` Network  
 - `Austin_trips_am.tntp` AM Peak hourDemand  
 - `Austin Flow Map 1 12-15-08.jpg`  Map  

## Dimensions
Zones: 7,388
Nodes: 7,388
Links: 18.961
Trips: 739351

## Units
FIXME
Time: 
Distance: 
Cost: 

## Generalized Cost Weights
FIXME
Toll: 
Distance: 

## Solutions


## Known Issues
FIXME translate to Github Issues

Hong Zheng identified the following duplicate links in the Austin network: [1879, 1884]; [4079, 4080]; [4080, 4079]; [4436, 6583]; [6583, 4436]. Notice that the parameters of the duplicate links are not the same. Any reports using this network until 2012 should be assumed to rely on the network with the duplicated links. Any reports using this network from 2013 onwards should be assumed to rely on the network with the first link in each duplicated pair.