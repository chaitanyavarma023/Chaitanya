static int dump_add_packet(unsigned char *h80211, int caplen, struct rx_info *ri, int cardnum) {
    unsigned char sa_mac[6];

    if (((h80211[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_MGT)) {
        uint8_t frame_type = h80211[0] & 0xF0;

        if (frame_type == 0x00) {
            // Ensure the captured length is sufficient for fixed parameters
            if (caplen < 24 + 4) {
                return 0;
            }

            // Extract Source MAC Address
            memcpy(sa_mac, &h80211[10], 6);
            printf("Association Request detected from Source MAC: %02x:%02x:%02x:%02x:%02x:%02x\n",
                   sa_mac[0], sa_mac[1], sa_mac[2], sa_mac[3], sa_mac[4], sa_mac[5]);

            // Parse IE elements
            unsigned char *ie_ptr = h80211 + 24 + 4;
            int ie_length = caplen - (24 + 4);

            int supports_80211k = 0;
            int supports_80211r = 0;
            int supports_80211v = 0;
            int supports_80211w = 0;

            while (ie_length >= 2) {
                uint8_t id = ie_ptr[0];
                uint8_t len = ie_ptr[1];

                if (len + 2 > ie_length) {
                    break;
                }

                if (id == IEEE80211_ELEMID_RM_CAP) {
                    // 802.11k: Check Octet 1, Bit 1 (0x02)
                    if (len >= 2 && (ie_ptr[2] & 0x02) { // ie_ptr[2] is Octet 0, ie_ptr[3] is Octet 1
                        supports_80211k = 1;
                    }
                } else if (id == IEEE80211_ELEMID_MOBILITY_DOMAIN) {
                    // 802.11r: Check FT Capability Bit 0 (0x01)
                    if (len >= 3 && (ie_ptr[2 + 2] & 0x01)) { // FT Capability is at Octet 2 (ie_ptr[4])
                        supports_80211r = 1;
                    }
                } else if (id == IEEE80211_ELEMID_EXT_CAP) {
                    // 802.11v: Check Octet 3, Bit 3 (0x08)
                    if (len >= 4 && (ie_ptr[2 + 2] & 0x08) { // Octet 3 is at ie_ptr[5]
                        supports_80211v = 1;
                    }
                } else if (id == IEEE80211_ELEMID_RSN_CAP) {
                    
                    if (len >= 10 && (ie_ptr[10] & 0x32) { 
                        supports_80211w = 1;
                    }
                }

                ie_ptr += (len + 2);
                ie_length -= (len + 2);
            }

            printf("802.11k Support: %s\n", supports_80211k ? "Yes" : "No");
            printf("802.11r Support: %s\n", supports_80211r ? "Yes" : "No");
            printf("802.11v Support: %s\n", supports_80211v ? "Yes" : "No");
        }
    }
    return 0;
}


###############################################################################################################
#################################################################################################################




static int dump_add_packet(unsigned char *h80211, int caplen, struct rx_info *ri, int cardnum) {
    unsigned char sa_mac[6];

    if ((h80211[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_MGT) {
        uint8_t frame_subtype = h80211[0] & 0xF0; // Extract subtype from frame control

        // Process Probe Request (subtype 4, 0x40)
        if (frame_subtype == 0x40) { // Probe Request
            if (caplen < 24) {
                return 0;
            }
            // Extract Source MAC
            memcpy(sa_mac, &h80211[10], 6);
            printf("Probe Request detected from Source MAC: %02x:%02x:%02x:%02x:%02x:%02x\n",
                   sa_mac[0], sa_mac[1], sa_mac[2], sa_mac[3], sa_mac[4], sa_mac[5]);

            // Parse IE elements starting immediately after header
            unsigned char *ie_ptr = h80211 + 24;
            int ie_length = caplen - 24;

            int supports_80211n = 0;
            int supports_80211ac = 0;
            int supports_80211ax = 0;
            int supports_80211be = 0;

            while (ie_length >= 2) {
                uint8_t id = ie_ptr[0];
                uint8_t len = ie_ptr[1];

                if (len + 2 > ie_length) {
                    break;
                }

                if (id == IEEE80211_ELEMID_HT_CAP) {
                    supports_80211n = 1;
                } else if (id == IEEE80211_ELEMID_VHT_CAP) {
                    supports_80211ac = 1;
                } else if (id == IEEE80211_ELEMID_HE_CAP) {
                    if (len == 26 || len >= 25) { // Check HE Capabilities length
                        supports_80211ax = 1;
                    }
                } else if (id == IEEE80211_ELEMID_EHT_CAP) {
                    if (len == 21 || len >= 20) { // Check EHT Capabilities length
                        supports_80211be = 1;
                    }
                }

                ie_ptr += (len + 2);
                ie_length -= (len + 2);
            }

            printf("802.11n  Support: %s\n", supports_80211n ? "Yes" : "No");
            printf("802.11ac Support: %s\n", supports_80211ac ? "Yes" : "No");
            printf("802.11ax Support: %s\n", supports_80211ax ? "Yes" : "No");
            printf("802.11be Support: %s\n", supports_80211be ? "Yes" : "No");
        }

        // Process Association Request (subtype 0, 0x00)
        else if (frame_subtype == 0x00) { // Association Request
            if (caplen < 24 + 4) {
                return 0;
            }
            // Extract Source MAC
            memcpy(sa_mac, &h80211[10], 6);
            printf("Association Request detected from Source MAC: %02x:%02x:%02x:%02x:%02x:%02x\n",
                   sa_mac[0], sa_mac[1], sa_mac[2], sa_mac[3], sa_mac[4], sa_mac[5]);

            // Parse IE elements after fixed parameters
            unsigned char *ie_ptr = h80211 + 24 + 4;
            int ie_length = caplen - (24 + 4);

            int supports_80211k = 0;
            int supports_80211r = 0;
            int supports_80211v = 0;
            int supports_80211w = 0;

            while (ie_length >= 2) {
                uint8_t id = ie_ptr[0];
                uint8_t len = ie_ptr[1];

                if (len + 2 > ie_length) {
                    break;
                }

                if (id == IEEE80211_ELEMID_RM_CAP) { // 802.11k
                    if (len >= 2 && (ie_ptr[3] & 0x02)) { // Check Octet 1, Bit 1 (0x02)
                        supports_80211k = 1;
                    }
                } else if (id == IEEE80211_ELEMID_MOBILITY_DOMAIN) { // 802.11r
                    if (len >= 3 && (ie_ptr[4] & 0x01)) { // FT Capability at Octet 2
                        supports_80211r = 1;
                    }
                } else if (id == IEEE80211_ELEMID_EXT_CAP) { // 802.11v
                    if (len >= 4 && (ie_ptr[5] & 0x08)) { // Octet 3, Bit 3 (0x08)
                        supports_80211v = 1;
                    }
                } else if (id == IEEE80211_ELEMID_RSN_CAP) { // 802.11w
                    if (len >= 19 && (ie_ptr[20] & 0x20)) { // Check bit 6 (0x20)
                        supports_80211w = 1;
                    }
                }

                ie_ptr += (len + 2);
                ie_length -= (len + 2);
            }

            printf("802.11k Support: %s\n", supports_80211k ? "Yes" : "No");
            printf("802.11r Support: %s\n", supports_80211r ? "Yes" : "No");
            printf("802.11v Support: %s\n", supports_80211v ? "Yes" : "No");
            printf("802.11w Support: %s\n", supports_80211w ? "Yes" : "No");
        }
    }
    return 0;
}