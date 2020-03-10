/ Record station info from nextbike API

\d .bikes

hdbdir:@[value;`hdbdir;hsym`$getenv`KDBHDB];
webpage:@[value;`webpage;"https://nextbike.net/maps/nextbike-live.json"];

// Request data from nextbike API
request:{
  .lg.o[`bikes;"Requesting data from nextbike for city ",c:raze .proc.params`cityno];
  /Retrieve data from website
  req:.Q.hg hsym `$webpage,"?city=",c;
  .lg.o[`bikes;"Returning data for city ",c];
  :req;
 };

// Get JSON log file name for date d
getjsonlog:{[d]
  :hsym`$raze[.proc.params`jsonlog],"/jsonlog_",(string[d]except"."),"_",raze .proc.params[`cityno],".txt";
 };

// Log output of API request to file
logbikedata:{[t;j]
  fn:getjsonlog`date$t;
  .lg.o[`bikes;"Writing to JSON log: ",f:.os.pth fn];
  /Open connection to file using current time on request
  hdat:hopen fn;
  /Write data on single line with corresponding time
  hdat string[t]," -- ",j,"\n";
  /Close connection to file.
  hclose hdat;
  .lg.o[`bikes;"Finished writing to JSON log: ",f];
 };

// Replay a JSON log into memory
replayjsonlog:{[d]
  if[()~key fn:getjsonlog d;
    .lg.o[`bikes;"Could not find log file, exiting early: ",.os.pth fn];
    :();
  ];
  .lg.o[`bikes;"Found log file, beginning replay: ",f:.os.pth fn];
  /Replay each line of log file in turn
  {mkplace . readlogline x}'[read0 fn];
  .lg.o[`bikes;"Finished replaying log file: ",f];
 };

// Parse line from log file
readlogline:{@[;1;.j.k]@[0 29 33 cut x;0;"P"$]0 2};

// Parse json into in memory table place
mkplace:{[t;parsed]
  .lg.o[`bikes;"Starting to parse JSON..."]
  /Extract tables from JSON
  tab:first[first[parsed`countries]`cities]`places;
  bike_tab:update name: (exec raze (count each bike_list) #' enlist each name from tab) from exec raze bike_list from tab;
  /Refactor data and extract relevant data
  tab:`address`bike_list`spot`bike_types`bike _`time xcols update time:.z.P^t,name:trim name from tab;
  bike_tab:`pedelac_battery`battery_pack _ `time`name xcols update time:.z.P^t,name:trim name,number:"I"$number,lock_types:raze lock_types from bike_tab;
  /Convert floats to ints where appropriate
  tab:@[tab;`uid`number`bikes`bike_racks`free_racks;`int$];
  tab:@[tab;`place_type`bike_numbers;"I"$];
  bike_tab:@[bike_tab;`bike_type`boardcomputer;`int$];
  .lg.o[`bikes;"Finished parsing JSON, adding to in memory tables"];
  /Insert data into table in memory
  `place insert tab;
  .lg.o[`bikes;"Added data to in memory table: place"];
  `bike_list insert bike_tab;
  .lg.o[`bikes;"Added data to in memory table: bike_list"];
 };

// Make request to nextbike API, log to disk and parse into in memory table 
fullbikedata:{
  .lg.o[`bikes;"Request started"];
  /Record time of request
  rt:.z.P;
  /Request data from nextbike API
  l:request[];
  /Write messages to out logs as requests are processed
  logbikedata[rt;l];
  /Parse JSON into a table and add to in memory table
  mkplace[rt;.j.k l];
  .lg.o[`bikes;"Request complete"];
 };

fullbikedataprotected:{[]@[fullbikedata;`;{[x].lg.e[`bikes]"Error running fullbikedata: ",x}]};

// Write data to disk for date d
writedown:{[d]
  dir:` sv .Q.par[hdbdir;d;`place],`;
  bikesdir:` sv .Q.par[hdbdir;d;`bike_list],`;
  .lg.o[`bikes;"Writing place data to: ",.os.pth dir];
  .lg.o[`bikes;"Writing bike_list data to: ",.os.pth bikesdir];
  dir set select from `. `place where time.date=(d);
  bikesdir set select from `. `bike_list where time.date=(d);
 };

// Clear data for date d
cleardate:{[d]
  delete from `place where time.date=d;
  delete from `bike_list where time.date=d;
 };

// Write yesterdays data to disk
eodwritedown:{
  writedown .z.d-1;
  cleardate .z.d-2;
 };

\d .

// Repeat for 14 days - every 30 seconds
.timer.repeat[.proc.cp[];.proc.cp[]+14D00:00;0D00:00:30;(.bikes.fullbikedataprotected;`);"belfastbikes"];

// At 6am each day, write down yesterdays data to hdb, and delete the data in memory from 2 days before
.timer.repeat[(.z.D+1)+06:00:00.000000;.z.d+14;0D01:00:00;(.bikes.eodwritedown;`);"dailyWritedownBikes"];
