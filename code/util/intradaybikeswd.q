// Gets the baseport past in from the command line.
conn:.Q.def[(enlist `conn)!enlist 1;.Q.opt .z.x][`conni]
// Opens a handle to rbd and calls the writedown function.
bikerdb: hopen conn+1;
bikerdb".bikes.writedown[.z.d]"
exit 0;
