#ifndef _WIDS_TOOL_H_
#define _WIDS_TOOL_H_

#include <sys/ioctl.h>
#include <time.h>

#define NULL_MAC (unsigned char *)"\x00\x00\x00\x00\x00\x00"
#define BROADCAST (unsigned char *)"\xFF\xFF\xFF\xFF\xFF\xFF"

#define IEEE80211_FC0_TYPE_MASK 0x0c
#define IEEE80211_FC0_TYPE_MGT 0x00
#define IEEE80211_FC0_TYPE_CTL 0x04
#define IEEE80211_FC0_TYPE_DATA 0x08
/* for TYPE_MGT */
#define IEEE80211_FC0_SUBTYPE_ASSOC_REQ 0x00
#define IEEE80211_FC0_SUBTYPE_ASSOC_RESP 0x10
#define IEEE80211_FC0_SUBTYPE_REASSOC_REQ 0x20
#define IEEE80211_FC0_SUBTYPE_REASSOC_RESP 0x30
#define IEEE80211_FC0_SUBTYPE_PROBE_REQ 0x40
#define IEEE80211_FC0_SUBTYPE_PROBE_RESP 0x50
#define IEEE80211_FC0_SUBTYPE_BEACON 0x80
#define IEEE80211_FC0_SUBTYPE_ATIM 0x90
#define IEEE80211_FC0_SUBTYPE_DISASSOC 0xa0
#define IEEE80211_FC0_SUBTYPE_AUTH 0xb0
#define IEEE80211_FC0_SUBTYPE_DEAUTH 0xc0
/* for TYPE_CTL */
#define IEEE80211_FC0_SUBTYPE_PS_POLL 0xa0
#define IEEE80211_FC0_SUBTYPE_RTS 0xb0
#define IEEE80211_FC0_SUBTYPE_CTS 0xc0
#define IEEE80211_FC0_SUBTYPE_ACK 0xd0
#define IEEE80211_FC0_SUBTYPE_CF_END 0xe0
#define IEEE80211_FC0_SUBTYPE_CF_END_ACK 0xf0
#define MAX_CARDS 8 /* maximum number of cards to capture from */

//***********
#define DEAUTH_idx 0
#define AUTH_idx 1
#define DISASSOC_idx 2
#define ASSOC_idx 3
#define RTS_idx 4
#define CTS_idx 5
#define FATA_idx 6
#define OMERTA_idx 7
#define POWER_SAVE_idx 8
#define MAl_ASSOC_idx 9
#define Block_ack_idx 10
#define MAL_AUTH_idx 11
#define MAL_PROBE_idx 12
#define ARR_SIZE 13
//***********

struct AP_info
{
	struct AP_info *next;
	time_t tinit, tlast;
	unsigned char da_mac[6];
	unsigned char sa_mac[6];
	unsigned char bss_mac[6];
	unsigned int atkcnt[ARR_SIZE];
	int power;
	int channel;
	struct timeval tv;
};

#endif
