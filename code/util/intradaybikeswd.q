// Gets the rdb port past in from the command line.
conn:.Q.def[(enlist `conn)!enlist 1;.Q.opt .z.x][`conn]
// Opens a handle to rbd and calls the writedown function.
bikerdb: hopen conn;
bikerdb".bikes.writedown[.z.d]"
exit 0;
