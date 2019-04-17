/ Record station info from nextbike API

hdbdir:@[value;`hdbdir;hsym`$getenv`KDBHDB];
webpage:@[value;`webpage;"https://nextbike.net/maps/nextbike-live.json"];

request:{
    .lg.o[`bikes;"Requesting data from nextbike for city ",c:raze .proc.params`cityno];
    /Retrieve data from website
    req:raze system"curl -s ",webpage,"?city=",c;
    .lg.o[`bikes;"Returning data for city ",c];
    :req;
    }

logbikedata:{[t;j]
    fn:hsym`$f:raze[.proc.params[`jsonlog]],"/jsonlog_",ssr[string[.z.D];".";""],"_",raze .proc.params[`cityno],".txt";
    .lg.o[`bikes;"Writing to JSON log: ",f];
    /Open connection to file using current time on request
    hdat:hopen fn;
    /Write data on single line with corresponding time
    hdat string[t]," -- ",j,"\n";
    /Close connection to file.
    hclose hdat;
    .lg.o[`bikes;"Finished writing to JSON log: ",f];
    }

mkplace:{[parsed]
    .lg.o[`bikes;"Starting to parse JSON..."]
    /Extract relevant data from JSON
    tab:first[first[parsed`countries]`cities]`places;
    tab:`address`bike_list`spot`bike_types`bike _`time xcols update time:.z.P,name:trim name from tab;
    /Convert floats to ints where appropriate
    tab:@[tab;`uid`number`bikes`bike_racks`free_racks;`int$];
    tab:@[tab;`place_type`bike_numbers;"I"$];
    .lg.o[`bikes;"Finished parsing JSON, adding to in memory table"];
    /Insert data into table in memory
    `place insert tab;
    .lg.o[`bikes;"Added data to in memory table: place"];
    }
    
fullbikedata:{
    .lg.o[`bikes;"Request started"];
    /Request data from nextbike API
    l:request[];
    /Write messages to out logs as requests are processed
    logbikedata[.z.P;l];
    /Parse JSON into a table and add to in memory table
    mkplace .j.k l;
    .lg.o[`bikes;"Request complete"];
    }

fullbikedataprotected:{[]@[fullbikedata;`;{[x].lg.e[`bikes]"Error running fullbikedata: ",x}]};


//Repeat for 14 days - every 30 seconds
.timer.repeat[.proc.cp[];.proc.cp[]+14D00:00;0D00:00:30;(fullbikedataprotected;`);"belfastbikes"]

//At 6am each day, write down yesterdays data to hdb, and delete the data in memory from 2 days before
writedown:{
    dir:` sv .Q.par[hdbdir;.z.d-1;`place],`;
    .lg.o[`bikes;"Writing data to: ",string dir];
    dir set select from place where time.date=.z.d-1;
    delete from `place where time.date=.z.d-2
    }

.timer.repeat[(.z.D+1)+06:00:00.000000;.z.d+14;0D01:00:00;(writedown;`);"dailyWritedownBikes"]
