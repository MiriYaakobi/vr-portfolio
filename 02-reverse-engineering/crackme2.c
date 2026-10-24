#include <stdio.h>
#include <string.h>

int main() {
    char input[64];
    // This is "entrypt" XORed with 0x42
    unsigned char secret[7] = {0x27, 0x2c, 0x36, 0x30, 0x3b, 0x32, 0x36};
    int i;
    int match = 1;

    printf("Password: ");

    if (scanf("%63s", input) == 1) {
        
        // Check length first
        if (strlen(input) != 7) {
            match = 0;
        } else {
            // Character by character XOR comparison
            for (i = 0; i < 7; i++) {
                if ((input[i] ^ 0x42) != secret[i]) {
                    match = 0;
                    break;
                }
            }
        }

        if (match) {
            printf("Correct. Flag: entrypoint{xor_is_awesome}\n");
        } else {
            printf("Wrong.\n");
        }
    }
    
    return 0;
}