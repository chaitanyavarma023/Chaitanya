

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pcap.h>
#include <net/if.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <netinet/in.h>
#include <endian.h>
#include <time.h>
#include <unistd.h>
#include "ie_parser.h"

#define SNAP_LEN 2304
#define PROMISC 1
#define TIMEOUT 500

void packet_handler(u_char *args, const struct pcap_pkthdr *header, const u_char *packet) {
    const struct ieee80211_radiotap_header *rtap;
    const struct ieee80211_mgmt *mgmt;
    const u_char *ies;
    int rtap_len;
    int ie_len;
    
    rtap = (struct ieee80211_radiotap_header *)packet;
    rtap_len = rtap->it_len;
    
    mgmt = (struct ieee80211_mgmt *)(packet + rtap_len);
    ies = (u_char *)(packet + rtap_len + sizeof(struct ieee80211_mgmt));
    ie_len = header->len - (rtap_len + sizeof(struct ieee80211_mgmt));

    if(mgmt->frame_control[0] == IEEE80211_FC0_TYPE_MGT) {
        if(mgmt->frame_control[1] == IEEE80211_FC1_SUBTYPE_PROBE_REQ ||
           mgmt->frame_control[1] == IEEE80211_FC1_SUBTYPE_ASSOC_REQ) {
            
            printf("\n[Client: %02x:%02x:%02x:%02x:%02x:%02x]\n",
                   mgmt->sa[0], mgmt->sa[1], mgmt->sa[2],
                   mgmt->sa[3], mgmt->sa[4], mgmt->sa[5]);

            parse_ies(ies, ie_len);
        }
    }
}

int main(int argc, char **argv) {
    char *dev;
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle;
    struct bpf_program fp;
    char filter_exp[] = "type mgt subtype probe-req or type mgt subtype assoc-req";
    bpf_u_int32 mask;
    bpf_u_int32 net;

    if(argc != 2) {
        fprintf(stderr, "Usage: %s <interface>\n", argv[0]);
        return 2;
    }

    dev = argv[1];
    
    if(pcap_lookupnet(dev, &net, &mask, errbuf) == -1) {
        fprintf(stderr, "Can't get netmask for device %s\n", dev);
        net = 0;
        mask = 0;
    }

    handle = pcap_open_live(dev, SNAP_LEN, PROMISC, TIMEOUT, errbuf);
    if(handle == NULL) {
        fprintf(stderr, "Couldn't open device %s: %s\n", dev, errbuf);
        return 2;
    }

    if(pcap_compile(handle, &fp, filter_exp, 0, net) == -1) {
        fprintf(stderr, "Couldn't parse filter %s: %s\n", filter_exp, pcap_geterr(handle));
        return 2;
    }

    if(pcap_setfilter(handle, &fp) == -1) {
        fprintf(stderr, "Couldn't install filter %s: %s\n", filter_exp, pcap_geterr(handle));
        return 2;
    }

    pcap_loop(handle, -1, packet_handler, NULL);
    pcap_close(handle);
    return 0;
}
