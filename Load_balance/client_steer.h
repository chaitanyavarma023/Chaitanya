#ifndef CLIENT_STEERING_H
#define CLIENT_STEERING_H

#include <stdint.h>

#define IEEE80211_FC0_TYPE_MASK   0x0C
#define IEEE80211_FC0_TYPE_MGT    0x00
#define IEEE80211_FC0_SUBTYPE_ASSOC_REQ  0x00
#define IEEE80211_FC0_SUBTYPE_PROBE_REQ  0x40

// Struct to store AP and client information
struct AP_info {
    uint8_t ap_mac[6];           // AP MAC address
    uint8_t *client_macs[50];    // List of associated clients' MAC addresses
    int client_count;            // Number of associated clients
    int capacity;                // Maximum capacity of clients this AP can support
    int load;                    // Current load of clients
};

// Function to detect client load and trigger steering
void detect_and_steer_clients(struct AP_info *ap_list, int ap_count);

// Function to disconnect a client (send deauthentication)
void disconnect_client(uint8_t *client_mac, uint8_t *ap_mac);

// Function to send Probe Response to a client (to encourage it to connect to a specific AP)
void send_probe_response(uint8_t *client_mac, uint8_t *ap_mac);

// Function to send Beacon frame to the client (to help with AP selection)
void send_beacon(uint8_t *ap_mac);

#endif // CLIENT_STEERING_H
