To compile the sproto as a dll, copy all .c and .h files to the openresty directory, then do:
gcc -shared -Llua -Iinclude\luajit-2.1 -o sprotocore.dll lua51.dll sproto.c lsproto.c
Move the generated sprotocore.dll to the BabyWarsServer directory so that it can be loaded by openresty.