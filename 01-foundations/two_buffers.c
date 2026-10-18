#include <stdio.h>

void analyze_stack() {
    char buffer_a[16];
    char buffer_b[32];

    printf("Let's check the stack order :)\n");
    printf("Address of buffer_a: %p\n", (void*)buffer_a);
    printf("Address of buffer_b: %p\n", (void*)buffer_b);
}

int main(void) {
    analyze_stack();
    return 0;
}