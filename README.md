# glassrom-landing
Where you need to go to get started with glassrom - be it flashing or building it

# building
sync lineageos

copy the patch-glassrom.bash to the root of your build directory

run bash patch-glassrom.bash

to undo just repo sync again

# using update generator

use either gcc or clang

clang -lreadline -luuid updates.c

however if you are on non-GNU

clang -Dnongnu updates.c

run it:

./a.out

the generated json can be used in the OTA updater
