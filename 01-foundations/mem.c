#include <stdio.h>
#include <string.h>

void greet(void) {
    char name[32];
    char extra[32];
    printf("Name: ");
    fgets(name, sizeof(name), stdin);
    printf("Hello, %s\n", name);
    fgets(extra, sizeof(extra), stdin);
}

int main(void) {
    greet();
    return 0;
}
