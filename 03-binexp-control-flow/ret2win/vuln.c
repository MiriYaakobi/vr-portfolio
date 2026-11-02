#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Educational scaffolding: Gadget farm to isolate ROP chain mechanics
void gadget_farm(void) { __asm__("pop %rdi; ret"); }

void win(void) {
	printf("Access granted. Flag: entrypoint{ret2win_success}\n");
	system("/bin/sh");
}

void win_args(int secret_code) {
	if (secret_code == 0xdeadbeef) {
		puts("Access granted! Secret code is correct. Spawning shell...");
		system("/bin/sh");
	} else {
		puts("Access denied. Incorrect secret code.");
	}
}

void vulnerable(void) {
	char buffer[128];
	puts("Enter data:");
	read(0, buffer, 256);
	puts("Done.");
}

int main(void) {
	setvbuf(stdout, NULL, _IONBF, 0);
	vulnerable();
	return 0;
}
