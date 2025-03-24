
#define _GNU_SOURCE
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>

#ifndef TIOCGWINSZ
#include <sys/termios.h>
#endif

#include <arpa/inet.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <limits.h>
#include <netinet/in.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#include <assert.h>
#include <json-c/json.h>
#include <sys/wait.h>
#include <uci.h>

#include "interface_setup.h"
#include "radiotap/radiotap.h"
#include "radiotap/radiotap_iter.h"
#include "wids_tool.h"

#define REFRESH_RATE 60000000UL // To send Data to Cloud In micro sec
#define DEBUG_PRINT 0 // to print debug messages
//#define REFRESH_RATE 5000000UL					// In
// micro sec
#define CLEAN_AP_TIME (int)(REFRESH_RATE * 2.3) // In sec
#define MAX_DEVICE_STORAGE 6000



#define IEEE80211_FC0_TYPE_MGT          0x00
#define IEEE80211_FC0_SUBTYPE_ASSOC_REQ 0x00

#define IEEE80211_ELEMID_RM_CAP         0x46  // 802.11k: RM Enabled Capabilities
#define IEEE80211_ELEMID_MOBILITY_DOMAIN 0x36 // 802.11r: Mobility Domain
#define IEEE80211_ELEMID_EXT_CAP        0x7F // 802.11v: Extended Capabilities
#define IEEE80211_ELEMID_RSN_CAP     0x30    // 802.11w: RSN INFO --> RSN cap
#define IEEE80211_ELEMID_HT_CAP      0x2D
#define IEEE80211_ELEMID_VHT_CAP     0xBF
#define IEEE80211_ELEMID_HE_CAP      0x00FF
#define IEEE80211_ELEMID_EHT_CAP     0x00FF
#define MAX_ASSOC_CLIENTS 100




static unsigned int linked_cnt = 0;
int becone_pre_secon,becone_present,AP_FLOOD_thresold=0,channel_for_ap=0;
int client_flood,epoal_key_log_off;
char *json_file = "/tmp/wids_tool.txt";

static struct local_options {
  struct AP_info *ap_1st;
  uint8_t do_exit;
  char *s_iface;
  char *phy;
} lopt;

static struct uci_opt {
  uint8_t deauth_d;
  uint8_t auth_d;
  uint8_t disassoc_d;
  uint8_t assoc_d;
  uint8_t rts_d;
  uint8_t cts_d;
  uint8_t fata_d;
  uint8_t omerta_d;
  uint8_t power_save_d;
  uint8_t apflood_d;
  uint8_t apflood_thresold;
  uint8_t mal_asso_d;
  uint8_t block_ack_d;
  uint8_t mal_auth_d;
  uint8_t mal_probe_d;
  uint8_t client_flood_d;
  uint8_t eapol_key_logoff_d;
} uopt = {.deauth_d = 0,
          .auth_d = 0,
          .disassoc_d = 0,
          .assoc_d = 0,
          .rts_d = 0,
          .cts_d = 0,
          .fata_d = 0,
          .omerta_d=0,
          .power_save_d=0,
          .apflood_d=0,
          .apflood_thresold=100,
          .mal_asso_d=0,
          .block_ack_d=0,
          .mal_auth_d=0,
          .mal_probe_d=0,
          .client_flood_d=0,
          .eapol_key_logoff_d=0,
 };

typedef struct uci_opts {
  const char *name;
  uint8_t *val;
} uci_opts;

struct wif *wi;

typedef struct attck_database {
  const char *attack_str;
  const char *event_type;
  uint8_t *opt_val;
  unsigned int threshold;
} attck_database;

static const struct attck_database attack_data[ARR_SIZE] = {
    [DEAUTH_idx] = {"[Detected Deauth attack]", "Dos Attack", &(uopt.deauth_d),
                    60},
    [AUTH_idx] = {"[Detected Authentication Failure Attack]", "Dos Attack",
                  &(uopt.auth_d), 60},
    [DISASSOC_idx] = {"[Detected Disassociation Attack]", "Dos Attack",
                      &(uopt.disassoc_d), 60},
    [ASSOC_idx] = {"[Detected Association Attack]", "Dos Attack",
                   &(uopt.assoc_d), 60},
    [RTS_idx] = {"[Detected RTS Abuse]", "RTS abuse", &(uopt.rts_d), 200},
    [CTS_idx] = {"[Detected CTS Abuse]", "CTS abuse", &(uopt.cts_d), 200},
    [FATA_idx] = {"[Detected FATA jack Tool]", "Dos Attack", &(uopt.fata_d), 2},
    [OMERTA_idx] = {"[Detected Omerta]", "Dos Attack", &(uopt.omerta_d),20},
    [POWER_SAVE_idx] = {"[Detected Power Save Attack]", "Dos Attack", &(uopt.power_save_d),50},
    [MAl_ASSOC_idx] = {"[Detected Malformed frame - Association request]", "Dos Attack", &(uopt.mal_asso_d),60},
    [Block_ack_idx] = {"[Detected Block Ack Attack]", "Dos Attack", &(uopt.block_ack_d), 50},
    [MAL_AUTH_idx] = {"[Detected Malformed frame - Authentication request]", "Dos Attack", &(uopt.mal_auth_d), 100},
    [MAL_PROBE_idx] = {"[Detected Malformed frame - Probe Request]", "Dos Attack", &(uopt.mal_probe_d), 200},
};

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

            int supports_80211n = 0;
            int supports_80211ac = 0;
            int supports_80211ax = 0;
            int supports_80211be = 0;
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
//		printf("Detected IE: ID=%d, Length=%d\n", id, len);

		if (id == IEEE80211_ELEMID_HT_CAP) {

                        supports_80211n = 1;
                    }
		if (id == IEEE80211_ELEMID_VHT_CAP){

			supports_80211ac = 1;
		}

		 if (id == IEEE80211_ELEMID_HE_CAP){
		 // printf("Extended Capabilities Octet 3: 0x%02x, 0x%02x, 0x%02x,  x0x%02x\n  ", ie_ptr[0],ie_ptr[1], ie_ptr[2], ie_ptr[3]);
			if (ie_ptr[2] == 0x23 ){
                        supports_80211ax = 1;
		}

		}
		 if (id == IEEE80211_ELEMID_EHT_CAP){
		//	printf("EHT  Detected IE: ID=%d, Length=%d\n", id, len);
			if (ie_ptr[2] == 0x6c || ie_ptr[2] == 0x24) {
                        supports_80211be = 1;
                }
		}
		 if (id == IEEE80211_ELEMID_RM_CAP) {
                    // 802.11k: Check Octet 1, Bit 1 (0x02)
                    if (len >= 2 && (ie_ptr[2] & 0x02)) { // ie_ptr[2] is Octet 0, ie_ptr[3] is Octet 1
                        supports_80211k = 1;
                    }
                }
		 if (id == IEEE80211_ELEMID_MOBILITY_DOMAIN) {
                    // 802.11r: Check FT Capability Bit 0 (0x01)
                    if (len >= 3 && (ie_ptr[2 + 2] & 0x01)) { // FT Capability is at Octet 2 (ie_ptr[4])
                        supports_80211r = 1;
                    }
                }
		 if (id == IEEE80211_ELEMID_EXT_CAP) {
                    // 802.11v: Check Octet 3, Bit 3 (0x08)
                    if (len >= 4 && (ie_ptr[2 + 2] & 0x08)) { // Octet 3 is at ie_ptr[5]
                        supports_80211v = 1;
                    }
                }
		 if (id == 0x30 ) {
		//	printf("Extended Capabilities Octet 3: 0x%02x0x%02x\n  ", ie_ptr[20], ie_ptr[21]);
                    // 802.11w: Check RSn cap, Bit 6 (0x0020)
                    if (len >= 19 && ( ie_ptr[20] & 0xc0)) { // bit 6: PFM
                        supports_80211w = 1;
                    }
                }

                ie_ptr += (len + 2);
                ie_length -= (len + 2);
            }

	    printf("802.11n  Support: %s\n", supports_80211n ? "Yes" : "No");
            printf("802.11ac Support: %s\n", supports_80211ac ? "Yes" : "No");
            printf("802.11ax Support: %s\n", supports_80211ax ? "Yes" : "No");
            printf("802.11be Support: %s\n", supports_80211be ? "Yes" : "No");

            printf("802.11k Support: %s\n", supports_80211k ? "Yes" : "No");
            printf("802.11r Support: %s\n", supports_80211r ? "Yes" : "No");
            printf("802.11v Support: %s\n", supports_80211v ? "Yes" : "No");
	    printf("802.11w Support: %s\n", supports_80211w ? "Yes" : "No");
        }
    }
    return 0;
}


static int setup_card(char *iface, struct wif **wis) {
  REQUIRE(iface != NULL);
  REQUIRE(wis != NULL);

  struct wif *wi;

  wi = wi_open(iface);
  if (!wi)
    return (-1);
  *wis = wi;

  return (0);
}

static int check_monitor(struct wif *wi, int *fd_raw, int *fdh) {
  int monitor;
  char ifname[64];

  monitor = wi_get_monitor(wi);
  if (monitor != 0) {
    strncpy(ifname, wi_get_ifname(wi), sizeof(ifname) - 1);
    ifname[sizeof(ifname) - 1] = 0;

    wi_close(wi);
    wi = wi_open(ifname);
    if (!wi) {
      printf("Can't reopen %s\n", ifname);
      exit(1);
    }

    *fd_raw = wi_fd(wi);
    if (*fd_raw > *fdh)
      *fdh = *fd_raw;
  }
  return (0);
}

static void sighandler(int signum) {
  if (signum == SIGINT || signum == SIGTERM) {
    lopt.do_exit = 1;
    printf("\n\033[31mBBye... ;)\033[0m\n");
  }
}


int  uci_get_value(const char* config, const char* section, const char* option) {
    char cmd[100];
    char value[10];
    char* result = NULL;
    FILE* fp;

    // Construct the command
    snprintf(cmd, sizeof(cmd), "uci get %s.%s.%s", config, section, option);

    // Execute the command and read its output
    fp = popen(cmd, "r");
    if (fp == NULL) {
        perror("popen failed");
        return 0;
    }

    // Read the output of the command
    if (fgets(value, sizeof(value), fp) != NULL) {
        // Remove trailing newline
        value[strcspn(value, "\n")] = '\0';
        // Allocate memory for the result and copy the value
        result = strdup(value);
    }

    int temp = atoi((result));
    // Close the pipe
    pclose(fp);

    return temp;
}

static int read_uci() {
  struct uci_context *uci_ctx = uci_alloc_context();
  struct uci_package *uci_pkg;
  struct uci_section *uci_s;

  static const struct uci_opts uci_opt[] = {
      {"deauth_detect", &(uopt.deauth_d)},
      {"disassoc_detect", &(uopt.disassoc_d)},
      {"rts_abuse", &(uopt.rts_d)},
      {"cts_abuse", &(uopt.cts_d)},
      {"auth_detect", &(uopt.auth_d)},
      {"assoc_detect", &(uopt.assoc_d)},
      {"fata_jack_detect", &(uopt.fata_d)},
      {"omerta_detect",&(uopt.omerta_d)},
      {"power_save_detect",&(uopt.power_save_d)},
      {"apflood_detect", &(uopt.apflood_d)},
      {"apflood_thresold", &(uopt.apflood_thresold)},
      {"malframe_asso_detect", &(uopt.mal_asso_d)},
      {"block_ack_detect", &(uopt.block_ack_d)},
      {"mal_auth_detect", &(uopt.mal_auth_d)},
      {"mal_probe_detect", &(uopt.mal_probe_d)},
      {"client_flood_detect", &(uopt.client_flood_d)},
      {"eapol_key_logoff",&(uopt.eapol_key_logoff_d)},
};

  if (uci_load(uci_ctx, "rogue", &uci_pkg) != 0 || !uci_ctx) {
    return 1;
  }
  uci_s = uci_lookup_section(uci_ctx, uci_pkg, "attack_detection");
  if (!uci_s) {
    return 1;
  }

  int i;
  for (i = 0; i < sizeof(uci_opt) / sizeof(uci_opt[0]); ++i) {
    const char *opt1 = uci_lookup_option_string(uci_ctx, uci_s, uci_opt[i].name);

    *uci_opt[i].val =(opt1 == NULL) ? 0 : ((strcmp(opt1, "1") == 0) ? (uint8_t)1 : (uint8_t)0);
    if( !(strcmp(uci_opt[i].name,"apflood_thresold")))
    {
        if ( opt1 == NULL )
        {
            *uci_opt[i].val=(uint8_t)0;
        }
        else
        {
            *uci_opt[i].val=(uint8_t)atoi(opt1);
        }
    }
  }
   AP_FLOOD_thresold = uci_get_value("rogue", "attack_detection", "apflood_thresold");
  return 0;
}



struct AP_info* swap(struct AP_info * ptr1, struct AP_info * ptr2)
{
    struct AP_info* tmp = ptr2->next;
    ptr2->next = ptr1;
    ptr1->next = tmp;
    return ptr2;
}

int sortdatabase( struct AP_info **head ,int count )
{
     struct AP_info ** h;
     int i, j, swapped;
     h=head;

     if(h == NULL)
     {
         return 0;
     }

     for (i = 0; i <= count; i++)
     {
         h = head;
         if(h == NULL )
         {
             return 0;
         }
         swapped = 0;
         for (j = 0; j < count - i - 1; j++)
         {
               struct AP_info * p1 = *h;
               struct AP_info * p2 = p1->next;
               struct tm* tm1 = localtime(&p1->tlast); // tm1 for current
               int current_min = tm1->tm_min;
               int current_sec = tm1->tm_sec;

               struct tm* tm2 = localtime(&(p2->tlast));
               int index_min = tm2->tm_min;
               int index_sec = tm2->tm_sec;
               if(  ( index_min < current_min ) || ( ( index_min == current_min ) && ( index_sec < current_sec ) ) )
               {
                   /* update the link after swapping */
                   *h = swap(p1, p2);
                   swapped = 1;
               }

               h = &(*h)->next;
         }

         if (swapped == 0)
         {
             break;
         }
     }
}



int main(int argc, char *argv[])
{
    if (argc != 3)
    {
        printf("Invalid argument!\n");
        printf("Usage: wids_tool \"physical interface name\" \"interface name\"\n");
        return 1;
    }

    if (read_uci() != 0)
    {
        printf("Please check config file.\n");
        return 1;
    }
    memset(&lopt, 0, sizeof(lopt));
    struct AP_info *ap_cur, *ap_next;
    lopt.s_iface = argv[2];
    lopt.do_exit = 0;
    char ifnam[64];
    int fd_raw = -1;
    long time_slept = 0, cycle_time;
    int caplen = 0, fdh = 0;
    unsigned char buffer[4096];
    unsigned char *h80211;
    struct rx_info ri;
    struct timeval tv0;
    struct timeval tv1;
    struct timeval tv2;
    struct timeval tv3;
    fd_set rfds;
    int wi_read_failed = 0;
    int i = 0;
    lopt.phy = argv[1];
    char cmd[100];
    sprintf(cmd, "/bin/sh /usr/lib/lua/luci/ap/wids_tool.sh start %s %s",lopt.phy, lopt.s_iface);
    system(cmd);
    if (setup_card(lopt.s_iface, &wi) != 0)
    {
        printf("Card failed to initialize.\n");
        return (EXIT_FAILURE);
    }
    fd_raw = wi_fd(wi);
    if (fd_raw > fdh)
    {
        fdh = fd_raw;
    }

    struct sigaction action;
    action.sa_flags = 0;
    action.sa_handler = &sighandler;
    sigemptyset(&action.sa_mask);

    if (sigaction(SIGINT, &action, NULL) == -1)
    {
        perror("sigaction(SIGINT)");
    }
    if (sigaction(SIGTERM, &action, NULL) == -1)
    {
        perror("sigaction(SIGTERM)");
    }
    while (1)
    {
        if (lopt.do_exit)
        {
            break;
        }
        gettimeofday(&tv1, NULL);
        cycle_time = 1000000UL * (tv1.tv_sec - tv3.tv_sec) + (tv1.tv_usec - tv3.tv_usec);
        if (cycle_time > 500000)
        {
            gettimeofday(&tv3, NULL);
            if (lopt.s_iface != NULL)
            {
                check_monitor(wi, &fd_raw, &fdh);
            }
        }
        if (lopt.s_iface != NULL)
        {
            /* capture one packet */
            FD_ZERO(&rfds);
            FD_SET(fd_raw, &rfds); // NOLINT(hicpp-signed-bitwise)
            tv0.tv_sec = 0;
            tv0.tv_usec = REFRESH_RATE;
            gettimeofday(&tv1, NULL);
            if (select(fdh + 1, &rfds, NULL, NULL, &tv0) < 0)
            {
                if (errno == EINTR)
                {
                    gettimeofday(&tv2, NULL);
                    time_slept += 1000000UL * (tv2.tv_sec - tv1.tv_sec) + (tv2.tv_usec - tv1.tv_usec);
                    continue;
                }
                perror("select failed");
                return (EXIT_FAILURE);
            }
        }
        gettimeofday(&tv2, NULL);

        time_slept += 1000000UL * (tv2.tv_sec - tv1.tv_sec) + (tv2.tv_usec - tv1.tv_usec);

        if (lopt.s_iface != NULL)
        {
            if (FD_ISSET(fd_raw,&rfds)) // NOLINT(hicpp-signed-bitwise)
            {
                memset(buffer, 0, sizeof(buffer));
                h80211 = buffer;
                if ((caplen = wi_read(wi, NULL, NULL, h80211, sizeof(buffer), &ri)) == -1 )
                {
                    wi_read_failed++;
                    if (wi_read_failed > 1)
                    {
                        lopt.do_exit = 1;
                        break;
                    }
                    strncpy(ifnam, wi_get_ifname(wi), sizeof(ifnam) - 1);
                    ifnam[sizeof(ifnam) - 1] = 0;
                    wi_close(wi);
                    wi = wi_open(ifnam);
                    if (!wi)
                    {
                        printf("Can't reopen %s\n", ifnam);
                        exit(EXIT_FAILURE);
                    }
                    fd_raw = wi_fd(wi);
                    if (fd_raw > fdh)
                    {
                        fdh = fd_raw;
                    }
                    break;
                }
                wi_read_failed = 0;
                dump_add_packet(h80211, caplen, &ri, i);
            }
        }
    }
    char cmd_stop[100];
    sprintf(cmd_stop, "/bin/sh /usr/lib/lua/luci/ap/wids_tool.sh stop %s &",lopt.s_iface);
    system(cmd_stop);
    remove(json_file);
    return (EXIT_SUCCESS);
}

