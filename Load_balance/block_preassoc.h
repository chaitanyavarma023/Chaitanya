#ifndef BLOCK_ASSOCIATION_H
#define BLOCK_ASSOCIATION_H

#include <stdint.h>

#define IEEE80211_FC0_TYPE_MASK  0x0C
#define IEEE80211_FC0_TYPE_MGT   0x00
#define IEEE80211_FC0_SUBTYPE_ASSOC_REQ  0x00

// Function to block an Association Request
void block_association_request(unsigned char *h80211, int caplen);

// Function to send an Association Response with "denied" status
void send_assoc_reject(unsigned char *client_mac);

// Function to send a crafted packet to the client
void send_packet_to_client(unsigned char *frame, size_t frame_len);

#endif // BLOCK_ASSOCIATION_H
