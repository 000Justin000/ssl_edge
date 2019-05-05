# Philadelphia Network
A large-scale network for the Delaware Valley Region.

## Source
Provided by Dr. W. Thomas Walker, Manager, Office of Corridor/Systems Planning, Delaware Valley Regional Planning Commission, Philadelphia, PA, and are released with his permission. David Boyce compiled most of this metadata.
Via: http://www.bgu.ac.il/~bargera/tntp/


## Scenario
The year of the estimated/predicted flows is unknown.

The origin-destination data file (Philadelphia.trips) contains 24 hour flows (vehicles/day) between the 1525 zones in the DVRPC region.  All entries are integer.  

## Contents

 - `Philadelphia_net.tntp` Network  
 - `Philadelphia_trips.tntp` Demand  
 - `Philadelphia_node.tntp` Node coordinates  
 - `Philadelphia_toll.tntp`  Link tolls  

## Dimensions  
Zones: 1,525	 
Nodes: 13,389	
Links: 40,003	
Trips: 18,503,872 total; 14,336,062 interzonal

## Units
Time: Minutes
Distance: Miles
Speed: 
Cost: Cents
Coordinates: Node coordinates are given in units of 0.01 miles (i.e. divide by 100 to get the values in miles). 

## Generalized Cost Weights
Toll: 0.055 minutes/cent
Distance: 0

## Solutions

## Known Issues
FIXME translate to Github Issues

## Link Attributes

The fields of each link record are as follows:

1. from node  
2. to node  
3. capacity (24 hour)  
4. length (miles)  
5. free flow travel time (minutes)  
6. speed (entries do not correspond to free flow speeds, and meaning is unknown)  
7. toll  
8. link type  

The link types are as follows:

1. freeway, including freeway to freeway ramps  
2. parkway  
3. principal arterial  
4. secondary arterial  
5. unused  
6. collector/local  
7. approach link, including centroid connectors  
8. ramp  
9. dummy link  

Because of software capacity limitations, some links are coded with an implicit assumption of no U-turns.

## Uses

The network was applied in a Build vs. No-Build comparison of the effects of a pair of freeway-to-freeway ramps.  These ramps are included in Philadelphia.net as follows:

link description | from | to | capacity | length | free-flow time
--- | --- | --- | --- | --- | ---
I-295 EB to NJ 42 SB | 18177 | 13346 | 16,575	veh/day | 0.80 miles | 1.48 minutes  
NJ 42 NB to I-295 WB | 1334 | 13388 | 16,575	veh/day | 0.82 miles | 1.48 minutes  

To solve the traffic assignment problem without these ramps, it is advised to set the free-flow travel time to a large number, such as 99.99 minutes.  In this way, the effect of the network coding on the solution is maintained in both solutions.
