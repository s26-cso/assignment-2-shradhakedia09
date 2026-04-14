#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h> // dl: dynamic loading, allows loading .so files at runtime

//.so file?
// shared object(a C file someone else compiled that we can use in our program)

int main()
{
    char op[7];
    int n1, n2;

    while (scanf("%s %d %d", op, &n1, &n2) == 3)
    {
        char libname[20]; 
        sprintf(libname, "lib%s.so", op); //if op=add then libname is libadd.so

        void *ref = dlopen(libname, RTLD_LAZY);
        // ref is like a reference to the book I want to opne
        // RTLD_LAZY: doesn't read everything immediately and loads what is needed whe it is needed.
        // returns NULL if library is not found

        if (ref==NULL)
        {
            printf("Error\n");
            continue;
        }

        int (*operation)(int, int);  // this is a FUNCTION POINTER; operation is a variable that holds a function. takes 2 ints and reutrns 1 int 
        operation = dlsym(ref, op); //finding function named op inside library

        if (operation==NULL)
        {
            printf("Error\n");
            dlclose(ref);
            continue;
        }

        int answer = operation(n1, n2);
        printf("%d\n", answer);

        dlclose(ref); //closes the book/library, frees memory.
    }

    return 0;
}