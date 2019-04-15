/ Record station info from Next Bike API

request:{
    /Retrieve data from website and save to xml file
    system[raze"wget -q -O bikes.xml ",.proc.params[`webpage],"?city=",.proc.params[`cityno]];
    /Read contents of xml file
    raze read0`:bikes.xml
    }

cleandata:{[data]
    /Remove any spaces between quotations in preparation for parsing
    pos:o where any (o:where data = " ") within/: 2 cut where "\""=/:data;
    data[pos]:"^";
    data
    }

logbikedata:{[t;f]
   /Open connection to file using current time on request
   hdat:hopen hsym`$raze[.proc.params[`xmllog]],"/","xmllog_",ssr[string[.z.D];".";""],"_",raze .proc.params[`cityno],".txt";
   /Write data on single line possibly with time appending each time
   hdat string[t]," -- ", f,"\n";
   /Close connection to file.
   hclose[hdat];
   }

parsedata:{[x]
    /Use .xml.q p function to parse
    .xml.p[x]
    }

mkplace:{[parsed]
    tab:uj/[enlist each parsed[0;2;0;2;0;2;;1]];
    tab:update time:.z.P, name:ssr'[name;"^";" "] from tab;
    iplace:update "F"$lat, "F"$lng, "I"$uid, "I"$number, "I"$bikes, "I"$bike_racks,
      "I"$free_racks, 0^"I"$","vs'bike_numbers, "I"$place_type, "I"$rack_locks
      from `spot`bike_types`bike _`time xcols tab;
   `place insert iplace;
   }
    
fullbikedata:{
    /Write messages to out logs as requests are processed
    .lg.o[1;"Starting to make requests"];
    l:cleandata request[];
    .lg.o[1;"Finished request"];
    logbikedata[.z.P;l];
    .lg.o[1;"Finished logging"];
    parsed:parsedata[l]; 
    .lg.o[1;"Finished parsing"];
    mkplace[parsed];
    .lg.o[1;"Requests complete!"];
    }

fullbikedataprotected:{[] @[fullbikedata;`;{[x]lg.e[1]"Error running fullbikedata: ",x}]};


//Repeat for 14 days - every 30 seconds
.timer.repeat[.proc.cp[];.proc.cp[]+14D00:00;0D00:00:30;(fullbikedataprotected;`);"belfastbikes"]

//At 6am each day, write down yesterdays data to hdb, and delete the data in memory from 2 days before
writedown:{
    (hsym `$raze"hdb/",string (.z.d-1),`$"/place/") set select from place where time.date=(.z.d-1);
    delete from `place where time.date=(.z.d-2)
    }

.timer.repeat[(.z.D+1)+06:00:00.000000;.z.d+14;0D01:00:00;(writedown;`);"dailyWritedownBikes"]
