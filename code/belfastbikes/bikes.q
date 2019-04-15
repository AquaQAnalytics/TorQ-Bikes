/ Record station info from Next Bike API

hdbdir:@[value;`hdbdir;hsym`$getenv`KDBHDB];
webpage:@[value;webpage;"https://nextbike.net/maps/nextbike-live.json"];

request:{
    /Retrieve data from website
    raze system[raze"curl -s ",webpage,"?city=",.proc.params[`cityno]]
    }

logbikedata:{[t;f]
    /Open connection to file using current time on request
    hdat:hopen hsym`$raze[.proc.params[`jsonlog]],"/jsonlog_",ssr[string[.z.D];".";""],"_",raze .proc.params[`cityno],".txt";
    /Write data on single line possibly with time appending each time
    hdat string[t]," -- ", f,"\n";
    /Close connection to file.
    hclose[hdat];
    }

mkplace:{[parsed]
    tab:first[first[parsed`countries]`cities]`places;
    tab:`spot`bike_types`bike _`time xcols update time:.z.P, name:trim name from tab;
    iplace:update "i"$uid, "i"$number, "i"$bikes, "i"$bike_racks,
      "i"$free_racks, 0^"I"$bike_numbers, "I"$place_type, "i"$rack_locks from tab;
   `place insert iplace;
   }
    
fullbikedata:{
    /Write messages to out logs as requests are processed
    .lg.o[1;"Starting to make requests"];
    l:request[];
    .lg.o[1;"Finished request"];
    logbikedata[.z.P;l];
    .lg.o[1;"Finished logging"];
    parsed:.j.k[l]; 
    .lg.o[1;"Finished parsing"];
    mkplace[parsed];
    .lg.o[1;"Requests complete!"];
    }

fullbikedataprotected:{[] @[fullbikedata;`;{[x]lg.e[1]"Error running fullbikedata: ",x}]};


//Repeat for 14 days - every 30 seconds
.timer.repeat[.proc.cp[];.proc.cp[]+14D00:00;0D00:00:30;(fullbikedataprotected;`);"belfastbikes"]

//At 6am each day, write down yesterdays data to hdb, and delete the data in memory from 2 days before
writedown:{
    (` sv .Q.par[hdbdir;.z.d;`place],`) set select from place where time.date=(.z.d-1);
    delete from `place where time.date=(.z.d-2)
    }

.timer.repeat[(.z.D+1)+06:00:00.000000;.z.d+14;0D01:00:00;(writedown;`);"dailyWritedownBikes"]
