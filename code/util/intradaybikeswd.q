// Gets the rdb port past in from the command line.
conn:.Q.def[(enlist `conn)!enlist 0Nj;.Q.opt .z.x][`conn];
// Opens a handle to rbd and calls the writedown function.
bikerdb:@[hopen;conn;{-2 "Cannot perform writedown. Unable to open connection, error: ",x;exit 1;}];
bikerdb".bikes.writedown[.z.d]";
exit 0;
