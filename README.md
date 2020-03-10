# Belfast Bikes

## Parsing JSON Data from the Nextbike Platform

Given a semi-public API, what data analysis can we perform? The nextbike platform
provides both an XML and JSON output of raw data, detailing bike availability at
each station in the cities and countries where the system exists. In particular,
we have used the JSON output to focus on Belfast (city 238) where BelfastBikes
has 46 docking stations available to rent a bike from, although we can modify
this to be any city on the platform, using the respective city number.

Using kdb+ we can pull this data periodically off the web and create a time-series
database to perform analysis on, made possible by the TorQ framework. Taking
advantage of TorQ's capabilities, the process has been enhanced to include error
logging, history logging and an extension of the kdb+ built-in timer, making it
repeat until a specified end-time. This allows us to view log files
for any date and rebuild the usage of BelfastBikes for any date where we have
collected information.

Once a database has been created, time-series and other queries can be executed
against the data.  For example, by rebuilding the table for yesterday's bike
usage, we can create a mapping of 'routes' that each bike has taken, i.e. where
the bike has checked in during those 24 hours and at what time during the day.

## Requirements

Basic knowledge of the q programming language and linux commands is assumed.
This project requires the use of KDB+ and the [TorQ framework](https://github.com/AquaQAnalytics/TorQ).

## Getting Started:

- These bash commands will give directions on downloading TorQ and our BIKE message
  package. The BIKE package will be placed on top of the base TorQ package.
	
1. Make a directory to check the git repos into, and a directory to deploy the system to.

		~/$ mkdir git deploy
		~/$ ls
		deploy  git
	
2. Change to the git directory and clone the BIKE parser and TorQ repositories.

		~/$ cd git
		~/git$ git clone https://github.com/AquaQAnalytics/TorQ-Bikes.git
		~/git$ git clone https://github.com/AquaQAnalytics/TorQ.git
		~/git$ ls
		TorQ-Bikes  TorQ
	
3. Change to the deploy directory and copy the contents of TorQ into it.

		~/git$ cd ../deploy/
 		~/deploy$ cp -r ../git/TorQ/* ./
	
4. Copy the contents of the BIKE parsers repo into the same directory, allowing overwrites.

		~/deploy$ cp -r ../git/TorQ-Bikes/* ./

You should have a combination of each directories content included in the deploy directory:

	~/deploy$ ls
        appconfig  aquaq-torq-brochure.pdf  code  config  docs  hdb  html  lib  LICENSE  logs  mkdocs.yml  README.md  setenv.sh  start_bikes.sh  tests  torq.q  jsonlogs     
	
## Configuration

You can change the city that you want to collect data for by changing the city
number variable in `deploy/setenv.sh`; the default value is 238 (Belfast).
The default port is set at 14000, this can also be modified in the `setenv.sh` script.

## Launching the Process
To launch the process of retrieving data about each BelfastBikes location, run 
the `start_bikes.sh` executable in the `deploy` directory
```
~/deploy$ ./start_bikes.sh
```
This launches the bikes.q script wrapped in the TorQ framework.

## Collecting Data

The process will run for 14 days once it starts, collecting data every 30 seconds.
During the 14 days, there will be a write down to hdb at 6am every day using the 
previous day's data and saved by date. Within the bikes.q script there are timer 
functions for both the collection of data and the writedown which can be modified.

The jsonlogs directory will contain previously collected data in its raw JSON 
format for each day, saved as a plain text file. 

## Replaying Logs

In order to replay a log file on disk, the following can be used:
```
.bikes.replayjsonlog 2019.01.01
```
This reads the data to the in memory table `place`, which can then be written to
disk with:
```
.bikes.writedown 2019.01.01
```

## Example Usage

To query the persisted data in the HDB, we can either load in a specific date
partition to a q session, or load the entire database to perform queries across
a range of dates. To load in the HDB to a q session we can run the following command:
```
~/deploy$ q  hdb/
```
Example query:
```
//For each bike, select the first time it appears at a distinct location (uid)
s:1_select uid,time by bike_numbers from select from (update a:differ uid by bike_numbers from ungroup select time,uid,bike_numbers from place where date=2017.09.22) where a=1

//Create a table showing each uid and its corresponding location name, latitude and longitude, keyed by uid
t:`uid xkey select name,lat,lng by distinct uid from place where date=2017.09.22

//Join together news and t, select relevant information grouped by bike numbers
data:select uid,name,lat,lng,time by bike_numbers from lj[ungroup s;t]
```
This data table table will show what stations a particular bike has visited during that day.

Within a partition of our database, we could find out how many rentals were taken
from each docking station during that particular day:
```
q)`x xdesc (select count i by uid from d:select from (update d: differ uid by bike_numbers from  (ungroup select time,uid,bike_numbers from place)) where d,not bike_numbers=0) lj select last name by uid from place
uid    | x   name
-------| ----------------------------------------------
316463 | 127 "Donegall Quay"
263966 | 101 "City Hall"
566097 | 43  "Titanic Belfast Met"
318535 | 23  "Odyssey / Sydenham Road"
517255 | 23  "Queens University / University Road "
318553 | 21  "Arthur Street / Chichester Street"
1257794| 19  "Belfast City Hospital Lisburn Rd"
555520 | 17  "Queens University / Botanic Gardens "
```
Or we could query across a range of dates within the database, for example
finding out which docking station was most popular across several days:
```
q)select max x,Dock:name where x=max x by date from ((select count i by uid,date from d:select from (update d: differ uid by bike_numbers from (ungroup select date,time, uid,bike_numbers from place)) where d,not bike_numbers=0) lj select last name by uid from place)
date      | x   Dock
----------| -----------------------------------------
2017.09.23| 153 "Titanic Belfast Met"
2017.09.24| 127 "Donegall Quay"
2017.09.25| 41  "Alfred Street / St Malachy's Church"
```
