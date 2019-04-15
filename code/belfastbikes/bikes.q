/ Record station info from nextbike API

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
    tab:`address`bike_list`spot`bike_types`bike _`time xcols update time:.z.P, name:trim name from tab;
    /Convert floats to ints where appropriate
    tab:@[tab;`uid`number`bikes`bike_racks`free_racks;`int$];
    tab:@[tab;`place_type`bike_numbers;"I"$];
    /Insert data into table in memory
    `place insert tab;
    }
    
fullbikedata:{
    /Request data from nextbike API
    .lg.o[1;"Starting to make requests"];
    l:request[];
    .lg.o[1;"Finished request"];
    /Write messages to out logs as requests are processed
    logbikedata[.z.P;l];
    .lg.o[1;"Finished logging"];
    /Parse JSON string into dictionary
    parsed:.j.k[l]; 
    .lg.o[1;"Finished parsing"];
    /Convert results to table and add to in memory table
    mkplace[parsed];
    .lg.o[1;"Requests complete!"];
    }

fullbikedataprotected:{[]@[fullbikedata;`;{[x]lg.e[1]"Error running fullbikedata: ",x}]};


//Repeat for 14 days - every 30 seconds
.timer.repeat[.proc.cp[];.proc.cp[]+14D00:00;0D00:00:30;(fullbikedataprotected;`);"belfastbikes"]

//At 6am each day, write down yesterdays data to hdb, and delete the data in memory from 2 days before
writedown:{
    (` sv .Q.par[hdbdir;.z.d;`place],`)set select from place where time.date=.z.d-1;
    delete from `place where time.date=.z.d-2
    }

.timer.repeat[(.z.D+1)+06:00:00.000000;.z.d+14;0D01:00:00;(writedown;`);"dailyWritedownBikes"]
