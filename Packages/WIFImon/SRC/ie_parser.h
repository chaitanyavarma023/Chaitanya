
#ifndef IE_PARSER_H
#define IE_PARSER_H

#include <stdio.h>
#include <stdint.h>

void parse_ies(const u_char *ies, int ie_len) {
    const u_char *p = ies;
    int remaining = ie_len;

    while(remaining > 2) {
        uint8_t id = p[0];
        uint8_t len = p[1];
        
        if(len > remaining - 2) break;

        switch(id) {
            case 1:  // Supported Rates
                printf("  Supported Rates: ");
                for(int i=0; i<len; i++) printf("%.1f ", (p[2+i] & 0x7f) * 0.5);
                printf("\n");
                break;

            case 45: // HT Capabilities
                printf("  802.11n (HT) Capabilities:\n");
                printf("    Channel Width: %s\n", (p[2] & 0x02) ? "40MHz" : "20MHz");
                printf("    MIMO Streams: %d\n", ((p[2] >> 2) & 0x03) + 1);
                break;

            case 48: // RSN
                printf("  Security: WPA2/WPA3\n");
                printf("    AKM: %s\n", (p[6] == 0x02) ? "WPA3-SAE" : "WPA2-PSK");
                printf("    Cipher: %s\n", (p[4] == 0x04) ? "CCMP" : "GCMP-256");
                break;

            case 191: // VHT Capabilities
                printf("  802.11ac (VHT) Capabilities:\n");
                printf("    Channel Width: %dMHz\n", 
                      ((p[3] & 0x03) == 0) ? 160 : 
                      ((p[3] & 0x03) == 1) ? 80 : 40);
                printf("    SU/MU-MIMO: %s\n", (p[4] & 0x08) ? "MU-MIMO" : "SU-MIMO");
                break;

            case 255: // Vendor Specific (HE)
                if(len >= 4 && p[2] == 0x00 && p[3] == 0x10 && p[4] == 0x18) {
                    printf("  802.11ax (HE) Capabilities:\n");
                    printf("    OFDMA: %s\n", (p[5] & 0x01) ? "Yes" : "No");
                    printf("    TWT: %s\n", (p[5] & 0x20) ? "Yes" : "No");
                }
                break;
        }

        remaining -= len + 2;
        p += len + 2;
    }
}

#endif
