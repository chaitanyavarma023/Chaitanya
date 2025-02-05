#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <net/if.h>
#include <linux/if_packet.h>
#include <errno.h>
#include "block_association.h"

// Function to block an Association Request by sending an Association Response with Denial
void block_association_request(unsigned char *h80211, int caplen) {
    unsigned char sa_mac[6];  // Source MAC Address (client's MAC trying to associate)

    // Check if the frame is a Management frame and is an Association Request
    if ((h80211[0] & IEEE80211_FC0_TYPE_MASK) == IEEE80211_FC0_TYPE_MGT) {
        uint8_t frame_type = h80211[0] & 0xF0;

        // Check for Association Request frame (Subtype 0x00)
        if (frame_type == IEEE80211_FC0_SUBTYPE_ASSOC_REQ) {
            // Extract the source MAC address of the client trying to associate
            memcpy(sa_mac, &h80211[4], 6);  // Copy client MAC address (from frame header)

            printf("Blocking Association Request from client: %02x:%02x:%02x:%02x:%02x:%02x\n",
                   sa_mac[0], sa_mac[1], sa_mac[2], sa_mac[3], sa_mac[4], sa_mac[5]);

            // Send Association Response with "denied" status code
            send_assoc_reject(sa_mac);
        }
    }
}

// Function to send an Association Response with rejection status (0x0003 - Association Denied)
void send_assoc_reject(unsigned char *client_mac) {
    unsigned char assoc_resp_frame[30];  // Minimum size for an Association Response frame
    memset(assoc_resp_frame, 0, sizeof(assoc_resp_frame));

    // Set the Frame Control field (Management Frame, Association Response)
    assoc_resp_frame[0] = 0x00;  // Frame Control: Management frame
    assoc_resp_frame[1] = 0x01;  // Subtype: Association Response

    // Destination MAC Address: the client trying to associate
    memcpy(&assoc_resp_frame[4], client_mac, 6);  // Set the destination MAC

    // Set Status Code to "Association Denied" (0x0003)
    assoc_resp_frame[24] = 0x03;  // Status Code: Denied
    assoc_resp_frame[25] = 0x00;

    // Send the rejection packet back to the client (inject it into the network)
    send_packet_to_client(assoc_resp_frame, sizeof(assoc_resp_frame));
}

// Function to send the crafted packet to the client (via raw socket)
void send_packet_to_client(unsigned char *frame, size_t frame_len) {
    int sockfd;
    struct sockaddr_ll sa;
    struct ifreq ifr;

    // Open a raw socket to send the frame
    if ((sockfd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) == -1) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // Set up the interface for sending the packet
    strncpy(ifr.ifr_name, "wlan0", sizeof(ifr.ifr_name) - 1);  // Replace "wlan0" with your interface
    if (ioctl(sockfd, SIOCGIFINDEX, &ifr) < 0) {
        perror("ioctl failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    sa.sll_ifindex = ifr.ifr_ifindex;

    // Send the crafted packet on the network interface
    if (sendto(sockfd, frame, frame_len, 0, (struct sockaddr*)&sa, sizeof(struct sockaddr_ll)) == -1) {
        perror("sendto failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    printf("Association Response sent to block client\n");

    // Close the socket
    close(sockfd);
}
