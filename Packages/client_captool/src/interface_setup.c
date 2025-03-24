#include <stdio.h>
#include <time.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <netpacket/packet.h>
#include <linux/if_ether.h>
#include <linux/if.h>
#include <linux/wireless.h>
#include <netinet/in.h>
#include <linux/if_tun.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <dirent.h>
#include <sys/utsname.h>
#include <net/if_arp.h>
#include <limits.h>
#include <assert.h>

#include "interface_setup.h"
#include "radiotap/radiotap.h"
#include "radiotap/radiotap_iter.h"
#include "byteorder.h"
#define ARPHRD_ETHERNET 1
#define LINKTYPE_IEEE802_11 105
#define ARPHRD_IEEE80211 801
#define ARPHRD_IEEE80211_PRISM 802
#define ARPHRD_IEEE80211_FULL 803

#ifndef ETH_P_80211_RAW
#define ETH_P_80211_RAW 25
#endif

typedef enum
{
    DT_NULL = 0,
    DT_WLANNG,
    DT_HOSTAP,
    DT_MADWIFI,
    DT_MADWIFING,
    DT_BCM43XX,
    DT_ORINOCO,
    DT_ZD1211RW,
    DT_ACX,
    DT_MAC80211_RT,
    DT_AT76USB,
    DT_IPW2200

} DRIVER_TYPE;

struct priv_linux
{
    int fd_in, arptype_in;
    int fd_out, arptype_out;
    int fd_main;
    int fd_rtc;

    DRIVER_TYPE drivertype; /* inited to DT_UNKNOWN on allocation by wi_alloc */

    FILE *f_cap_in;

    struct pcap_file_header pfh_in;

    int sysfs_inject;
    int channel;
    int freq;
    int rate;
    int tx_power;
    char *wlanctlng; /* XXX never set */
    char *iwpriv;
    char *iwconfig;
    char *ifconfig;
    char *wl;
    char *main_if;
    unsigned char pl_mac[6];
    int inject_wlanng;
};

const unsigned long int crc_tbl_osdep[256] = {0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F,
											  0xE963A535, 0x9E6495A3, 0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988,
											  0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91, 0x1DB71064, 0x6AB020F2,
											  0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
											  0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9,
											  0xFA0F3D63, 0x8D080DF5, 0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172,
											  0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B, 0x35B5A8FA, 0x42B2986C,
											  0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
											  0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423,
											  0xCFBA9599, 0xB8BDA50F, 0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
											  0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D, 0x76DC4190, 0x01DB7106,
											  0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
											  0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D,
											  0x91646C97, 0xE6635C01, 0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
											  0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457, 0x65B0D9C6, 0x12B7E950,
											  0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
											  0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7,
											  0xA4D1C46D, 0xD3D6F4FB, 0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
											  0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9, 0x5005713C, 0x270241AA,
											  0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
											  0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81,
											  0xB7BD5C3B, 0xC0BA6CAD, 0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
											  0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683, 0xE3630B12, 0x94643B84,
											  0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
											  0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB,
											  0x196C3671, 0x6E6B06E7, 0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
											  0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5, 0xD6D6A3E8, 0xA1D1937E,
											  0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
											  0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55,
											  0x316E8EEF, 0x4669BE79, 0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236,
											  0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F, 0xC5BA3BBE, 0xB2BD0B28,
											  0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
											  0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F,
											  0x72076785, 0x05005713, 0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38,
											  0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21, 0x86D3D2D4, 0xF1D4E242,
											  0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
											  0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69,
											  0x616BFFD3, 0x166CCF45, 0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2,
											  0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB, 0xAED16A4A, 0xD9D65ADC,
											  0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
											  0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693,
											  0x54DE5729, 0x23D967BF, 0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94,
											  0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D};

int wi_get_monitor(struct wif *wi)
{
	assert(wi->wi_get_monitor);
	return wi->wi_get_monitor(wi);
}

int wi_write(struct wif *wi,
			 struct timespec *ts,
			 int dlt,
			 unsigned char *h80211,
			 int len,
			 struct tx_info *ti)
{
	assert(wi->wi_write);
	return wi->wi_write(wi, ts, dlt, h80211, len, ti);
}

int wi_read(struct wif *wi,
			struct timespec *ts,
			int *dlt,
			unsigned char *h80211,
			int len,
			struct rx_info *ri)
{
	assert(wi->wi_read);
	return wi->wi_read(wi, ts, dlt, h80211, len, ri);
}

void wi_close(struct wif *wi)
{
	assert(wi->wi_close);
	wi->wi_close(wi);
}

char *wi_get_ifname(struct wif *wi) { return wi->wi_interface; }

int wi_get_channel(struct wif *wi)
{
	assert(wi->wi_get_channel);
	return wi->wi_get_channel(wi);
}

void * wi_priv(struct wif * wi) { return wi->wi_priv; }

static unsigned long calc_crc_osdep(unsigned char *buf, int len)
{
    unsigned long crc = 0xFFFFFFFF;

    for (; len > 0; len--, buf++)
        crc = crc_tbl_osdep[(crc ^ *buf) & 0xFF] ^ (crc >> 8);

    return (~crc);
}

/* CRC checksum verification routine */

static int check_crc_buf_osdep(unsigned char *buf, int len)
{
    unsigned long crc;

    if (len < 0)
        return 0;

    crc = calc_crc_osdep(buf, len);
    buf += len;
    return (((crc)&0xFF) == buf[0] && ((crc >> 8) & 0xFF) == buf[1] && ((crc >> 16) & 0xFF) == buf[2] && ((crc >> 24) & 0xFF) == buf[3]);
}

int getChannelFromFrequency(int frequency)
{
    if (frequency >= 2412 && frequency <= 2472)
        return (frequency - 2407) / 5;
    else if (frequency == 2484)
        return 14;

    else if (frequency >= 4920 && frequency <= 6100)
        return (frequency - 5000) / 5;
    else
        return -1;
}

static int linux_read(struct wif *wi,
                      struct timespec *ts,
                      int *dlt,
                      unsigned char *buf,
                      int count,
                      struct rx_info *ri)
{
    struct priv_linux *dev = wi_priv(wi);
    unsigned char tmpbuf[4096] __attribute__((aligned(8)));

    int caplen, n, got_signal, got_noise, got_channel, fcs_removed;

    n = got_signal = got_noise = got_channel = fcs_removed = 0;

    if ((unsigned)count > sizeof(tmpbuf))
        return (-1);

    if ((caplen = read(dev->fd_in, tmpbuf, count)) < 0)
    {
        if (errno == EAGAIN)
            return (0);

        perror("read failed");
        return (-1);
    }

    switch (dev->drivertype)
    {
    case DT_MADWIFI:
        caplen -= 4; /* remove the FCS for madwifi-old! only (not -ng)*/
        break;
    default:
        break;
    }

    memset(buf, 0, count);

    /* XXX */
    if (ri)
        memset(ri, 0, sizeof(*ri));

    if (dlt)
    {
        // TODO(jbenden): Future code could receive the actual linktype received.
        *dlt = LINKTYPE_IEEE802_11;
    }

    if (ts)
    {
        clock_gettime(CLOCK_REALTIME, ts);
    }

    if (dev->arptype_in == ARPHRD_IEEE80211_PRISM)
    {
        /* skip the prism header */
        if (tmpbuf[7] == 0x40)
        {
            /* prism54 uses a different format */
            if (ri)
            {
                ri->ri_power = (int32_t)load32_le(tmpbuf + 0x33);
                ri->ri_noise = (int32_t)load32_le(tmpbuf + 0x33 + 12);
                ri->ri_rate = load32_le(buf + 0x33 + 24) * 500000;

                got_signal = 1;
                got_noise = 1;
            }

            n = 0x40;
        }
        else
        {
            if (ri)
            {
                ri->ri_mactime = load64_le(tmpbuf + 0x5C - 48);
                ri->ri_channel = load32_le(tmpbuf + 0x5C - 36);
                ri->ri_power = (int32_t)load32_le(tmpbuf + 0x5C);
                ri->ri_noise = (int32_t)load32_le(tmpbuf + 0x5C + 12);
                ri->ri_rate = load32_le(tmpbuf + 0x5C + 24) * 500000;

                if (dev->drivertype == DT_MADWIFI || dev->drivertype == DT_MADWIFING)
                    ri->ri_power -= (int32_t)load32_le(tmpbuf + 0x68);

                got_channel = 1;
                got_signal = 1;
                got_noise = 1;
            }

            n = load32_le(tmpbuf + 4);
        }

        if (n < 8 || n >= caplen)
            return (0);
    }

    if (dev->arptype_in == ARPHRD_IEEE80211_FULL)
    {
        struct ieee80211_radiotap_iterator iterator;
        struct ieee80211_radiotap_header *rthdr;

        rthdr = (struct ieee80211_radiotap_header *)tmpbuf; //-V1032

        if (ieee80211_radiotap_iterator_init(&iterator, rthdr, caplen, NULL) < 0)
            return (0);

        /* go through the radiotap arguments we have been given
         * by the driver
         */

        while (ri && (ieee80211_radiotap_iterator_next(&iterator) >= 0))
        {

            switch (iterator.this_arg_index)
            {

            case IEEE80211_RADIOTAP_TSFT:
                // ri->ri_mactime = le64_to_cpu(*((uint64_t *)iterator.this_arg));
                break;

            case IEEE80211_RADIOTAP_DBM_ANTSIGNAL:
                if (!got_signal)
                {
                    if (*iterator.this_arg < 127)
                        ri->ri_power = *iterator.this_arg;
                    else
                        ri->ri_power = *iterator.this_arg - 255;

                    got_signal = 1;
                }
                break;

            case IEEE80211_RADIOTAP_DB_ANTSIGNAL:
                if (!got_signal)
                {
                    if (*iterator.this_arg < 127)
                        ri->ri_power = *iterator.this_arg;
                    else
                        ri->ri_power = *iterator.this_arg - 255;

                    got_signal = 1;
                }
                break;

            case IEEE80211_RADIOTAP_DBM_ANTNOISE:
                if (!got_noise)
                {
                    if (*iterator.this_arg < 127)
                        ri->ri_noise = *iterator.this_arg;
                    else
                        ri->ri_noise = *iterator.this_arg - 255;

                    got_noise = 1;
                }
                break;

            case IEEE80211_RADIOTAP_DB_ANTNOISE:
                if (!got_noise)
                {
                    if (*iterator.this_arg < 127)
                        ri->ri_noise = *iterator.this_arg;
                    else
                        ri->ri_noise = *iterator.this_arg - 255;

                    got_noise = 1;
                }
                break;

            case IEEE80211_RADIOTAP_ANTENNA:
                ri->ri_antenna = *iterator.this_arg;
                break;

            case IEEE80211_RADIOTAP_CHANNEL:
                ri->ri_channel = getChannelFromFrequency(
                    le16toh(*(uint16_t *)iterator.this_arg));
                got_channel = 1;
                break;

            case IEEE80211_RADIOTAP_RATE:
                ri->ri_rate = (*iterator.this_arg) * 500000;
                break;

            case IEEE80211_RADIOTAP_FLAGS:
                /* is the CRC visible at the end?
                 * remove
                 */
                if (*iterator.this_arg & IEEE80211_RADIOTAP_F_FCS)
                {
                    fcs_removed = 1;
                    caplen -= 4;
                }

                if (*iterator.this_arg & IEEE80211_RADIOTAP_F_BADFCS)
                    return (0);

                break;
            }
        }

        n = le16_to_cpu(rthdr->it_len);

        if (n <= 0 || n >= caplen)
            return (0);
    }

    caplen -= n;

    // detect fcs at the end, even if the flag wasn't set and remove it
    if (fcs_removed == 0 && check_crc_buf_osdep(tmpbuf + n, caplen - 4) == 1)
    {
        caplen -= 4;
    }

    memcpy(buf, tmpbuf + n, caplen);

    if (ri && !got_channel)
        ri->ri_channel = wi_get_channel(wi);

    return (caplen);
}

static int linux_write(struct wif *wi,
                       struct timespec *ts,
                       int dlt,
                       unsigned char *buf,
                       int count,
                       struct tx_info *ti)
{
    struct priv_linux *dev = wi_priv(wi);
    unsigned char maddr[6];
    int ret, usedrtap = 0;
    unsigned char tmpbuf[4096];
    unsigned char rate;
    unsigned short int *p_rtlen;

    unsigned char u8aRadiotap[] __attribute__((aligned(8))) = {
        0x00,
        0x00, // <-- radiotap version
        0x0c,
        0x00, // <- radiotap header length
        0x04,
        0x80,
        0x00,
        0x00, // <-- bitmap
        0x00, // <-- rate
        0x00, // <-- padding for natural alignment
        0x18,
        0x00, // <-- TX flags
    };

    /* Pointer to the radiotap header length field for later use. */
    p_rtlen = (unsigned short int *)(u8aRadiotap + 2); //-V1032

    if ((unsigned)count > sizeof(tmpbuf) - 22)
        return -1;

    /* XXX honor ti */
    if (ti)
    {
    }

    (void)ts;
    (void)dlt;

    rate = dev->rate;

    u8aRadiotap[8] = rate;

    switch (dev->drivertype)
    {

    case DT_MAC80211_RT:
        memcpy(tmpbuf, u8aRadiotap, sizeof(u8aRadiotap));
        memcpy(tmpbuf + sizeof(u8aRadiotap), buf, count);
        count += sizeof(u8aRadiotap);

        buf = tmpbuf;
        usedrtap = 1;
        break;

    case DT_WLANNG:
        /* Wlan-ng isn't able to inject on kernel > 2.6.11 */
        if (dev->inject_wlanng == 0)
        {
            perror("write failed");
            return (-1);
        }

        if (count >= 24)
        {
            /* for some reason, wlan-ng requires a special header */

            if ((((unsigned char *)buf)[1] & 3) != 3)
            {
                memcpy(tmpbuf, buf, 24);
                memset(tmpbuf + 24, 0, 22);

                tmpbuf[30] = (count - 24) & 0xFF;
                tmpbuf[31] = (count - 24) >> 8;

                memcpy(tmpbuf + 46, buf + 24, count - 24);

                count += 22;
            }
            else
            {
                memcpy(tmpbuf, buf, 30);
                memset(tmpbuf + 30, 0, 16);

                tmpbuf[30] = (count - 30) & 0xFF;
                tmpbuf[31] = (count - 30) >> 8; //-V610

                memcpy(tmpbuf + 46, buf + 30, count - 30);

                count += 16;
            }

            buf = tmpbuf;
        }
    /* fall through */
    case DT_HOSTAP:
        if ((((unsigned char *)buf)[1] & 3) == 2)
        {
            /* Prism2 firmware swaps the dmac and smac in FromDS packets */

            memcpy(maddr, buf + 4, 6);
            memcpy(buf + 4, buf + 16, 6);
            memcpy(buf + 16, maddr, 6);
        }
        break;
    default:
        break;
    }

    ret = write(dev->fd_out, buf, count);

    if (ret < 0)
    {
        if (errno == EAGAIN || errno == EWOULDBLOCK || errno == ENOBUFS || errno == ENOMEM)
        {
            usleep(10000);
            return (0);
        }

        perror("write failed");
        return (-1);
    }

    /* radiotap header length is stored little endian on all systems */
    if (usedrtap)
        ret -= letoh16(*p_rtlen);

    if (ret < 0)
    {
        if (errno == EAGAIN || errno == EWOULDBLOCK || errno == ENOBUFS || errno == ENOMEM)
        {
            usleep(10000);
            return (0);
        }

        perror("write failed");
        return (-1);
    }

    return (ret);
}
static int linux_set_channel(struct wif *wi, int channel)
{
    struct priv_linux *dev = wi_priv(wi);
    char s[32];
    int pid, status;
    struct iwreq wrq;

    memset(s, 0, sizeof(s));

    switch (dev->drivertype)
    {
    case DT_WLANNG:
        snprintf(s, sizeof(s) - 1, "channel=%d", channel);

        if ((pid = fork()) == 0)
        {
            close(0);
            close(1);
            close(2);
            IGNORE_NZ(chdir("/"));
            execl(dev->wlanctlng,
                  "wlanctl-ng",
                  wi->wi_interface,
                  "lnxreq_wlansniff",
                  s,
                  NULL);
            exit(1);
        }

        waitpid(pid, &status, 0);

        if (WIFEXITED(status))
        {
            dev->channel = channel;
            return (WEXITSTATUS(status));
        }
        else
            return (1);
        break;

    case DT_ORINOCO:
        snprintf(s, sizeof(s) - 1, "%d", channel);

        if ((pid = fork()) == 0)
        {
            close(0);
            close(1);
            close(2);
            IGNORE_NZ(chdir("/"));
            execlp(dev->iwpriv,
                   "iwpriv",
                   wi->wi_interface,
                   "monitor",
                   "1",
                   s,
                   NULL);
            exit(1);
        }

        waitpid(pid, &status, 0);
        dev->channel = channel;
        return 0;
        break; // yeah ;)

    case DT_ZD1211RW:
        snprintf(s, sizeof(s) - 1, "%d", channel);

        if ((pid = fork()) == 0)
        {
            close(0);
            close(1);
            close(2);
            IGNORE_NZ(chdir("/"));
            execlp(dev->iwconfig,
                   "iwconfig",
                   wi->wi_interface,
                   "channel",
                   s,
                   NULL);
            exit(1);
        }

        waitpid(pid, &status, 0);
        dev->channel = channel;
        return 0;
        break; // yeah ;)

    default:
        break;
    }

    memset(&wrq, 0, sizeof(struct iwreq));
    strncpy(wrq.ifr_name, wi->wi_interface, IFNAMSIZ);
    wrq.ifr_name[IFNAMSIZ - 1] = 0;

    wrq.u.freq.m = (double)channel;
    wrq.u.freq.e = (double)0;

    if (ioctl(dev->fd_in, SIOCSIWFREQ, &wrq) < 0)
    {
        usleep(10000); /* madwifi needs a second chance */

        if (ioctl(dev->fd_in, SIOCSIWFREQ, &wrq) < 0)
        {
            /*          perror( "ioctl(SIOCSIWFREQ) failed" ); */
            return (1);
        }
    }

    dev->channel = channel;

    return (0);
}
static int linux_get_channel(struct wif *wi)
{
    struct priv_linux *dev = wi_priv(wi);
    struct iwreq wrq;
    int fd, frequency;
    int chan = 0;

    memset(&wrq, 0, sizeof(struct iwreq));

    if (dev->main_if)
        strncpy(wrq.ifr_name, dev->main_if, IFNAMSIZ);
    else
        strncpy(wrq.ifr_name, wi->wi_interface, IFNAMSIZ);
    wrq.ifr_name[IFNAMSIZ - 1] = 0;

    fd = dev->fd_in;
    if (dev->drivertype == DT_IPW2200)
        fd = dev->fd_main;

    if (ioctl(fd, SIOCGIWFREQ, &wrq) < 0)
        return (-1);

    frequency = wrq.u.freq.m;
    if (frequency > 100000000)
        frequency /= 100000;
    else if (frequency > 1000000)
        frequency /= 1000;

    if (frequency > 1000)
        chan = getChannelFromFrequency(frequency);
    else
        chan = frequency;

    return chan;
}
static void do_free(struct wif *wi)
{
    struct priv_linux *pl = wi_priv(wi);

    if (pl->wlanctlng)
        free(pl->wlanctlng);

    if (pl->iwpriv)
        free(pl->iwpriv);

    if (pl->iwconfig)
        free(pl->iwconfig);

    if (pl->ifconfig)
        free(pl->ifconfig);

    if (pl->wl)
        free(pl->wl);

    if (pl->main_if)
        free(pl->main_if);

    free(pl);
    free(wi);
}
static void linux_close(struct wif *wi)
{
    struct priv_linux *pl = wi_priv(wi);

    if (pl->fd_in && pl->fd_out && pl->fd_in == pl->fd_out)
    {
        // Only close one if both are the same
        close(pl->fd_in);
    }
    else
    {
        if (pl->fd_in)
            close(pl->fd_in);
        if (pl->fd_out)
            close(pl->fd_out);
    }
    if (pl->fd_main)
        close(pl->fd_main);

    do_free(wi);
}
static int linux_fd(struct wif *wi)
{
    struct priv_linux *pl = wi_priv(wi);

    return pl->fd_in;
}
int wi_fd(struct wif * wi)
{
	assert(wi->wi_fd);
	return wi->wi_fd(wi);
}
static int linux_get_monitor(struct wif *wi)
{
    struct priv_linux *dev = wi_priv(wi);
    struct ifreq ifr;
    struct iwreq wrq;

    /* find the interface index */

    if (dev->drivertype == DT_IPW2200)
        return (0);

    memset(&ifr, 0, sizeof(ifr));
    strncpy(ifr.ifr_name, wi->wi_interface, sizeof(ifr.ifr_name) - 1);

    //     if( ioctl( fd, SIOCGIFINDEX, &ifr ) < 0 )
    //     {
    //         printf("Interface %s: \n", iface);
    //         perror( "ioctl(SIOCGIFINDEX) failed" );
    //         return( 1 );
    //     }

    /* lookup the hardware type */

    if (ioctl(wi_fd(wi), SIOCGIFHWADDR, &ifr) < 0)
    {
        printf("Interface %s: \n", wi->wi_interface);
        perror("ioctl(SIOCGIFHWADDR) failed");
        return (1);
    }

    /* lookup iw mode */
    memset(&wrq, 0, sizeof(struct iwreq));
    strncpy(wrq.ifr_name, wi->wi_interface, IFNAMSIZ);
    wrq.ifr_name[IFNAMSIZ - 1] = 0;

    if (ioctl(wi_fd(wi), SIOCGIWMODE, &wrq) < 0)
    {
        /* most probably not supported (ie for rtap ipw interface) *
         * so just assume its correctly set...                     */
        wrq.u.mode = IW_MODE_MONITOR;
    }

    if ((ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211 && ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211_PRISM && ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211_FULL) || (wrq.u.mode != IW_MODE_MONITOR && (dev->drivertype != DT_ORINOCO)))
    {
        return (1);
    }

    return (0);
}
static char * searchInside(const char * dir, const char * filename)
{
	char * ret;
	char * curfile;
	struct stat sb;
	int len, lentot;
	DIR * dp;
	struct dirent * ep;

	dp = opendir(dir);
	if (dp == NULL)
	{
		return NULL;
	}

	len = strlen(filename);
	lentot = strlen(dir) + 256 + 2;
	curfile = (char *) calloc(1, lentot);
	if (curfile == NULL)
	{
		(void) closedir(dp);
		return (NULL);
	}

	while ((ep = readdir(dp)) != NULL)
	{

		memset(curfile, 0, lentot);
		sprintf(curfile, "%s/%s", dir, ep->d_name);

		// Checking if it's the good file
		if ((int) strlen(ep->d_name) == len && !strcmp(ep->d_name, filename))
		{
			(void) closedir(dp);
			return curfile;
		}

		// If it's a directory and not a link, try to go inside to search
		if (lstat(curfile, &sb) == 0 && S_ISDIR(sb.st_mode)
			&& !S_ISLNK(sb.st_mode))
		{
			// Check if the directory isn't "." or ".."
			if (strcmp(".", ep->d_name) && strcmp("..", ep->d_name))
			{
				// Recursive call
				ret = searchInside(curfile, filename);
				if (ret != NULL)
				{
					(void) closedir(dp);
					free(curfile);
					return ret;
				}
			}
		}
	}
	(void) closedir(dp);
	free(curfile);
	return NULL;
}
char *wiToolsPath(const char *tool)
{
    char *path /*, *found, *env */;
    int i, nbelems;
    static const char *paths[] = {"/sbin",
                                  "/usr/sbin",
                                  "/usr/local/sbin",
                                  "/bin",
                                  "/usr/bin",
                                  "/usr/local/bin",
                                  "/tmp"};

    // Also search in other known location just in case we haven't found it yet
    nbelems = sizeof(paths) / sizeof(char *);
    for (i = 0; i < nbelems; i++)
    {
        path = searchInside(paths[i], tool);
        if (path != NULL)
            return path;
    }

    return NULL;
}
static int set_monitor(struct priv_linux * dev, char * iface, int fd)
{
	int pid, status;
	struct iwreq wrq;

	if (iface == NULL || strlen(iface) >= IFNAMSIZ)
	{
		return (1);
	}

	if (strcmp(iface, "prism0") == 0)
	{
		dev->wl = wiToolsPath("wl");
		if ((pid = fork()) == 0)
		{
			close(0);
			close(1);
			close(2);
			IGNORE_NZ(chdir("/"));
			ALLEGE(dev->wl != NULL);
			execl(dev->wl, "wl", "monitor", "1", NULL);
			exit(1);
		}
		waitpid(pid, &status, 0);
		if (WIFEXITED(status)) return (WEXITSTATUS(status));
		return (1);
	}
	else if (strncmp(iface, "rtap", 4) == 0)
	{
		return 0;
	}
	else
	{
		switch (dev->drivertype)
		{
			case DT_WLANNG:
				if ((pid = fork()) == 0)
				{
					close(0);
					close(1);
					close(2);
					IGNORE_NZ(chdir("/"));
					execl(dev->wlanctlng,
						  "wlanctl-ng",
						  iface,
						  "lnxreq_wlansniff",
						  "enable=true",
						  "prismheader=true",
						  "wlanheader=false",
						  "stripfcs=true",
						  "keepwepflags=true",
						  "6",
						  NULL);
					exit(1);
				}

				waitpid(pid, &status, 0);

				if (WIFEXITED(status)) return (WEXITSTATUS(status));
				return (1);
				break;

			case DT_ORINOCO:
				if ((pid = fork()) == 0)
				{
					close(0);
					close(1);
					close(2);
					IGNORE_NZ(chdir("/"));
					execlp(dev->iwpriv,
						   "iwpriv",
						   iface,
						   "monitor",
						   "1",
						   "1",
						   NULL);
					exit(1);
				}

				waitpid(pid, &status, 0);

				if (WIFEXITED(status)) return (WEXITSTATUS(status));

				return 1;
				break;

			case DT_ACX:
				if ((pid = fork()) == 0)
				{
					close(0);
					close(1);
					close(2);
					IGNORE_NZ(chdir("/"));
					execlp(dev->iwpriv,
						   "iwpriv",
						   iface,
						   "monitor",
						   "2",
						   "1",
						   NULL);
					exit(1);
				}

				waitpid(pid, &status, 0);

				if (WIFEXITED(status)) return (WEXITSTATUS(status));

				return 1;
				break;

			default:
				break;
		}

		memset(&wrq, 0, sizeof(struct iwreq));
		strncpy(wrq.ifr_name, iface, IFNAMSIZ);
		wrq.ifr_name[IFNAMSIZ - 1] = 0;
		wrq.u.mode = IW_MODE_MONITOR;

		if (ioctl(fd, SIOCSIWMODE, &wrq) < 0)
		{
			perror("ioctl(SIOCSIWMODE) failed");
			return (1);
		}

		if (dev->drivertype == DT_AT76USB)
		{
			sleep(3);
		}
	}

	/* couple of iwprivs to enable the prism header */

	if (!fork()) /* hostap */
	{
		close(0);
		close(1);
		close(2);
		IGNORE_NZ(chdir("/"));
		execlp("iwpriv", "iwpriv", iface, "monitor_type", "1", NULL);
		exit(1);
	}
	wait(NULL);

	if (!fork()) /* r8180 */
	{
		close(0);
		close(1);
		close(2);
		IGNORE_NZ(chdir("/"));
		execlp("iwpriv", "iwpriv", iface, "prismhdr", "1", NULL);
		exit(1);
	}
	wait(NULL);

	if (!fork()) /* prism54 */
	{
		close(0);
		close(1);
		close(2);
		IGNORE_NZ(chdir("/"));
		execlp("iwpriv", "iwpriv", iface, "set_prismhdr", "1", NULL);
		exit(1);
	}
	wait(NULL);

	return (0);
}
static int opensysfs(struct priv_linux * dev, char * iface, int fd)
{
	int fd2;
	char buf[256];

	if (iface == NULL || strlen(iface) >= IFNAMSIZ)
	{
		return 1;
	}

	/* ipw2200 injection */
	snprintf(buf, 256, "/sys/class/net/%s/device/inject", iface);
	fd2 = open(buf, O_WRONLY);

	/* bcm43xx injection */
	if (fd2 == -1)
	{
		snprintf(buf, 256, "/sys/class/net/%s/device/inject_nofcs", iface);
		fd2 = open(buf, O_WRONLY);
	}

	if (fd2 == -1) return -1;

	dup2(fd2, fd);
	close(fd2);

	dev->sysfs_inject = 1;
	return 0;
}
static int openraw(struct priv_linux * dev,
				   char * iface,
				   int fd,
				   int * arptype,
				   unsigned char * mac)
{
	REQUIRE(iface != NULL);

	struct ifreq ifr;
	struct ifreq ifr2;
	struct iwreq wrq;
	struct iwreq wrq2;
	struct packet_mreq mr;
	struct sockaddr_ll sll;
	struct sockaddr_ll sll2;

	if (strlen(iface) >= sizeof(ifr.ifr_name))
	{
		printf("Interface name too long: %s\n", iface);
		return (1);
	}

	/* find the interface index */
	memset(&ifr, 0, sizeof(ifr));
	strncpy(ifr.ifr_name, iface, sizeof(ifr.ifr_name) - 1);

	if (ioctl(fd, SIOCGIFINDEX, &ifr) < 0)
	{
		printf("Interface %s: \n", iface);
		perror("ioctl(SIOCGIFINDEX) failed");
		return (1);
	}

	memset(&sll, 0, sizeof(sll));
	sll.sll_family = AF_PACKET;
	sll.sll_ifindex = ifr.ifr_ifindex;

	switch (dev->drivertype)
	{
		case DT_IPW2200:
			/* find the interface index */

			if (dev->main_if == NULL)
			{
				perror("Missing interface name");
				return 1;
			}

			memset(&ifr2, 0, sizeof(ifr));
			strncpy(ifr2.ifr_name, dev->main_if, sizeof(ifr2.ifr_name) - 1);

			if (ioctl(dev->fd_main, SIOCGIFINDEX, &ifr2) < 0)
			{
				printf("Interface %s: \n", dev->main_if);
				perror("ioctl(SIOCGIFINDEX) failed");
				return (1);
			}

			/* set iw mode to managed on main interface */
			memset(&wrq2, 0, sizeof(struct iwreq));
			strncpy(wrq2.ifr_name, dev->main_if, IFNAMSIZ);
			wrq2.ifr_name[IFNAMSIZ - 1] = 0;

			if (ioctl(dev->fd_main, SIOCGIWMODE, &wrq2) < 0)
			{
				perror("SIOCGIWMODE");
				return 1;
			}
			wrq2.u.mode = IW_MODE_INFRA;
			if (ioctl(dev->fd_main, SIOCSIWMODE, &wrq2) < 0)
			{
				perror("SIOCSIWMODE");
				return 1;
			}

			/* bind the raw socket to the interface */

			memset(&sll2, 0, sizeof(sll2));
			sll2.sll_family = AF_PACKET;
			sll2.sll_ifindex = ifr2.ifr_ifindex;
			sll2.sll_protocol = htons(ETH_P_ALL);

			if (bind(dev->fd_main, //-V641
					 (struct sockaddr *) &sll2, //-V641
					 sizeof(sll2)) //-V641
				< 0)
			{
				printf("Interface %s: \n", dev->main_if);
				perror("bind(ETH_P_ALL) failed");
				return (1);
			}

			opensysfs(dev, dev->main_if, dev->fd_in);
			break;
		case DT_BCM43XX:
			opensysfs(dev, iface, dev->fd_in);
			break;
		case DT_WLANNG:
			sll.sll_protocol = htons(ETH_P_80211_RAW);
			break;
		default:
			sll.sll_protocol = htons(ETH_P_ALL);
			break;
	}

	/* lookup the hardware type */

	if (ioctl(fd, SIOCGIFHWADDR, &ifr) < 0)
	{
		printf("Interface %s: \n", iface);
		perror("ioctl(SIOCGIFHWADDR) failed");
		return (1);
	}

	/* lookup iw mode */
	memset(&wrq, 0, sizeof(struct iwreq));
	strncpy(wrq.ifr_name, iface, IFNAMSIZ);
	wrq.ifr_name[IFNAMSIZ - 1] = 0;

	if (ioctl(fd, SIOCGIWMODE, &wrq) < 0)
	{
		/* most probably not supported (ie for rtap ipw interface) *
		 * so just assume its correctly set...                     */
		wrq.u.mode = IW_MODE_MONITOR;
	}

	if ((ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211
		 && ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211_PRISM
		 && ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211_FULL)
		|| (wrq.u.mode != IW_MODE_MONITOR))
	{
		if (set_monitor(dev, iface, fd) && dev->drivertype != DT_ORINOCO)
		{
			ifr.ifr_flags &= ~(IFF_UP | IFF_BROADCAST | IFF_RUNNING);

			if (ioctl(fd, SIOCSIFFLAGS, &ifr) < 0)
			{
				perror("ioctl(SIOCSIFFLAGS) failed");
				return (1);
			}

			if (set_monitor(dev, iface, fd))
			{
				printf("Error setting monitor mode on %s\n", iface);
				return (1);
			}
		}
	}

	/* Is interface st to up, broadcast & running ? */
	if ((ifr.ifr_flags | IFF_UP | IFF_BROADCAST | IFF_RUNNING) != ifr.ifr_flags)
	{
		/* Bring interface up*/
		ifr.ifr_flags |= IFF_UP | IFF_BROADCAST | IFF_RUNNING;

		if (ioctl(fd, SIOCSIFFLAGS, &ifr) < 0)
		{
			perror("ioctl(SIOCSIFFLAGS) failed");
			return (1);
		}
	}
	/* bind the raw socket to the interface */

	if (bind(fd, (struct sockaddr *) &sll, sizeof(sll)) < 0) //-V641
	{
		printf("Interface %s: \n", iface);
		perror("bind(ETH_P_ALL) failed");
		return (1);
	}

	/* lookup the hardware type */

	if (ioctl(fd, SIOCGIFHWADDR, &ifr) < 0)
	{
		printf("Interface %s: \n", iface);
		perror("ioctl(SIOCGIFHWADDR) failed");
		return (1);
	}

	memcpy(mac, (unsigned char *) ifr.ifr_hwaddr.sa_data, 6); //-V512

	*arptype = ifr.ifr_hwaddr.sa_family;

	if (ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211
		&& ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211_PRISM
		&& ifr.ifr_hwaddr.sa_family != ARPHRD_IEEE80211_FULL)
	{
		if (ifr.ifr_hwaddr.sa_family == ARPHRD_ETHERNET)
			fprintf(stderr, "\nARP linktype is set to 1 (Ethernet) ");
		else
			fprintf(stderr,
					"\nUnsupported hardware link type %4d ",
					ifr.ifr_hwaddr.sa_family);

		fprintf(stderr,
				"- expected ARPHRD_IEEE80211,\nARPHRD_IEEE80211_"
				"FULL or ARPHRD_IEEE80211_PRISM instead.  Make\n"
				"sure RFMON is enabled: run 'airmon-ng start %s"
				" <#>'\nSysfs injection support was not found "
				"either.\n\n",
				iface);
		return (1);
	}

	/* enable promiscuous mode */

	memset(&mr, 0, sizeof(mr));
	mr.mr_ifindex = sll.sll_ifindex;
	mr.mr_type = PACKET_MR_PROMISC;

	if (setsockopt(fd, SOL_PACKET, PACKET_ADD_MEMBERSHIP, &mr, sizeof(mr)) < 0)
	{
		perror("setsockopt(PACKET_MR_PROMISC) failed");
		return (1);
	}

	return (0);
}
static int is_ndiswrapper(const char * iface, const char * path)
{
	int n, pid;
	if (!path || !iface || strlen(iface) >= IFNAMSIZ)
	{
		return 0;
	}
	if ((pid = fork()) == 0)
	{
		close(0);
		close(1);
		close(2);
		IGNORE_NZ(chdir("/"));
		execl(path, "iwpriv", iface, "ndis_reset", NULL);
		exit(1);
	}

	waitpid(pid, &n, 0);
	return ((WIFEXITED(n) && WEXITSTATUS(n) == 0));
}
static int do_linux_open(struct wif *wi, char *iface)
{
    int kver;
    struct utsname checklinuxversion;
    struct priv_linux *dev = wi_priv(wi);
    char *iwpriv = NULL;
    char strbuf[512];
    FILE *f;
    char athXraw[] = "athXraw";
    pid_t pid;
    int n;
    DIR *net_ifaces;
    struct dirent *this_iface;
    FILE *acpi = NULL;
    char buf[128];
    char *r_file = NULL;
    struct ifreq ifr;
    int iface_malloced = 0;

    if (iface == NULL || strlen(iface) >= IFNAMSIZ)
    {
        return (1);
    }

    dev->inject_wlanng = 1;
    dev->rate = 2; /* default to 1Mbps if nothing is set */

    /* open raw socks */
    if ((dev->fd_in = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) < 0)
    {
        perror("socket(PF_PACKET) failed");
        if (getuid() != 0)
            fprintf(stderr, "This program requires root privileges.\n");
        return (1);
    }

    if ((dev->fd_main = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) < 0)
    {
        perror("socket(PF_PACKET) failed");
        if (getuid() != 0)
            fprintf(stderr, "This program requires root privileges.\n");
        return (1);
    }

    /* Check iwpriv existence */
    iwpriv = wiToolsPath("iwpriv");

#ifndef CONFIG_LIBNL
    dev->iwpriv = iwpriv;
    dev->iwconfig = wiToolsPath("iwconfig");
    dev->ifconfig = wiToolsPath("ifconfig");

    if (!iwpriv)
    {
        fprintf(stderr,
                "Required wireless tools when compiled without libnl "
                "could not be found, exiting.\n");
        goto close_in;
    }
#endif

    /* Exit if ndiswrapper : check iwpriv ndis_reset */

    if (is_ndiswrapper(iface, iwpriv))
    {
        fprintf(stderr, "Ndiswrapper doesn't support monitor mode.\n");
        goto close_in;
    }

    if ((dev->fd_out = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL))) < 0)
    {
        perror("socket(PF_PACKET) failed");
        goto close_in;
    }
    /* figure out device type */

    /* mac80211 radiotap injection
     * detected based on interface called mon...
     * since mac80211 allows multiple virtual interfaces
     *
     * note though that the virtual interfaces are ultimately using a
     * single physical radio: that means for example they must all
     * operate on the same channel
     */

    /* mac80211 stack detection */
    memset(strbuf, 0, sizeof(strbuf));
    snprintf(strbuf,
             sizeof(strbuf) - 1,
             "ls /sys/class/net/%s/phy80211/subsystem >/dev/null 2>/dev/null",
             iface);

    if (system(strbuf) == 0)
        dev->drivertype = DT_MAC80211_RT;

    /* IPW2200 detection */
    memset(strbuf, 0, sizeof(strbuf));
    snprintf(strbuf,
             sizeof(strbuf) - 1,
             "ls /sys/class/net/%s/device/inject >/dev/null 2>/dev/null",
             iface);

    if (system(strbuf) == 0)
        dev->drivertype = DT_IPW2200;

    /* BCM43XX detection */
    memset(strbuf, 0, sizeof(strbuf));
    snprintf(strbuf,
             sizeof(strbuf) - 1,
             "ls /sys/class/net/%s/device/inject_nofcs >/dev/null 2>/dev/null",
             iface);

    if (system(strbuf) == 0)
        dev->drivertype = DT_BCM43XX;

    /* check if wlan-ng or hostap or r8180 */
    if (strlen(iface) == 5 && memcmp(iface, "wlan", 4) == 0)
    {
        memset(strbuf, 0, sizeof(strbuf));
        snprintf(strbuf,
                 sizeof(strbuf) - 1,
                 "wlancfg show %s 2>/dev/null | "
                 "grep p2CnfWEPFlags >/dev/null",
                 iface);

        if (system(strbuf) == 0)
        {
            if (uname(&checklinuxversion) >= 0)
            {
                /* uname succeeded */
                if (strncmp(checklinuxversion.release, "2.6.", 4) == 0 && strncasecmp(checklinuxversion.sysname, "linux", 5) == 0)
                {
                    /* Linux kernel 2.6 */
                    kver = atoi(checklinuxversion.release + 4);

                    if (kver > 11)
                    {
                        /* That's a kernel > 2.6.11, cannot inject */
                        dev->inject_wlanng = 0;
                    }
                }
            }
            dev->drivertype = DT_WLANNG;
            dev->wlanctlng = wiToolsPath("wlanctl-ng");
        }

        memset(strbuf, 0, sizeof(strbuf));
        snprintf(strbuf,
                 sizeof(strbuf) - 1,
                 "iwpriv %s 2>/dev/null | "
                 "grep antsel_rx >/dev/null",
                 iface);

        if (system(strbuf) == 0)
            dev->drivertype = DT_HOSTAP;

        memset(strbuf, 0, sizeof(strbuf));
        snprintf(strbuf,
                 sizeof(strbuf) - 1,
                 "iwpriv %s 2>/dev/null | "
                 "grep  GetAcx111Info  >/dev/null",
                 iface);

        if (system(strbuf) == 0)
            dev->drivertype = DT_ACX;
    }

    /* enable injection on ralink */

    if (strcmp(iface, "ra0") == 0 || strcmp(iface, "ra1") == 0 || strcmp(iface, "rausb0") == 0 || strcmp(iface, "rausb1") == 0)
    {
        memset(strbuf, 0, sizeof(strbuf));
        snprintf(strbuf,
                 sizeof(strbuf) - 1,
                 "iwpriv %s rfmontx 1 >/dev/null 2>/dev/null",
                 iface);
        IGNORE_NZ(system(strbuf));
    }

    /* check if newer athXraw interface available */

    if ((strlen(iface) >= 4 && strlen(iface) <= 6) && memcmp(iface, "ath", 3) == 0)
    {
        dev->drivertype = DT_MADWIFI;
        memset(strbuf, 0, sizeof(strbuf));

        snprintf(
            strbuf, sizeof(strbuf) - 1, "/proc/sys/net/%s/%%parent", iface);

        f = fopen(strbuf, "r");

        if (f != NULL)
        {
            // It is madwifi-ng
            dev->drivertype = DT_MADWIFING;
            fclose(f);

            /* should we force prism2 header? */

            sprintf((char *)strbuf, "/proc/sys/net/%s/dev_type", iface);
            f = fopen((char *)strbuf, "w");
            if (f != NULL)
            {
                fprintf(f, "802\n");
                fclose(f);
            }

            /* Force prism2 header on madwifi-ng */
        }
        else
        {
            // Madwifi-old
            memset(strbuf, 0, sizeof(strbuf));
            snprintf(strbuf,
                     sizeof(strbuf) - 1,
                     "sysctl -w dev.%s.rawdev=1 >/dev/null 2>/dev/null",
                     iface);

            if (system(strbuf) == 0)
            {

                athXraw[3] = iface[3];

                memset(strbuf, 0, sizeof(strbuf));
                snprintf(strbuf, sizeof(strbuf) - 1, "ifconfig %s up", athXraw);
                IGNORE_NZ(system(strbuf));

                iface = athXraw;
            }
        }
    }

    /* test if orinoco */

    if (memcmp(iface, "eth", 3) == 0)
    {
        if ((pid = fork()) == 0)
        {
            close(0);
            close(1);
            close(2);
            IGNORE_NZ(chdir("/"));
            execlp("iwpriv", "iwpriv", iface, "get_port3", NULL);
            exit(1);
        }

        waitpid(pid, &n, 0);

        if (WIFEXITED(n) && WEXITSTATUS(n) == 0)
            dev->drivertype = DT_ORINOCO;

        memset(strbuf, 0, sizeof(strbuf));
        snprintf(strbuf,
                 sizeof(strbuf) - 1,
                 "iwpriv %s 2>/dev/null | "
                 "grep get_scan_times >/dev/null",
                 iface);

        if (system(strbuf) == 0)
            dev->drivertype = DT_AT76USB;
    }

    /* test if zd1211rw */

    if (memcmp(iface, "eth", 3) == 0)
    {
        if ((pid = fork()) == 0)
        {
            close(0);
            close(1);
            close(2);
            IGNORE_NZ(chdir("/"));
            execlp("iwpriv", "iwpriv", iface, "get_regdomain", NULL);
            exit(1);
        }

        waitpid(pid, &n, 0);

        if (WIFEXITED(n) && WEXITSTATUS(n) == 0)
            dev->drivertype = DT_ZD1211RW;
    }

    if (dev->drivertype == DT_IPW2200)
    {
        r_file = (char *)calloc(33 + strlen(iface) + 1, sizeof(char));
        if (!r_file)
        {
            goto close_out;
        }
        snprintf(r_file,
                 33 + strlen(iface) + 1,
                 "/sys/class/net/%s/device/rtap_iface",
                 iface);

        if ((acpi = fopen(r_file, "r")) == NULL)
            goto close_out;
        memset(buf, 0, 128);
        IGNORE_ZERO(fgets(buf, 128, acpi));
        buf[127] = '\x00';
        // rtap iface doesn't exist
        if (strncmp(buf, "-1", 2) == 0)
        {
            // repoen for writing
            fclose(acpi);
            if ((acpi = fopen(r_file, "w")) == NULL)
                goto close_out;
            fputs("1", acpi);
            // reopen for reading
            fclose(acpi);
            if ((acpi = fopen(r_file, "r")) == NULL)
                goto close_out;
            IGNORE_ZERO(fgets(buf, 128, acpi));
        }
        fclose(acpi);
        acpi = NULL;

        // use name in buf as new iface and set original iface as main iface
        dev->main_if = (char *)malloc(strlen(iface) + 1);
        if (dev->main_if == NULL)
            goto close_out;
        memset(dev->main_if, 0, strlen(iface) + 1);
        strncpy(dev->main_if, iface, strlen(iface));

        iface = (char *)malloc(strlen(buf) + 1);
        if (iface == NULL)
            goto close_out;
        iface_malloced = 1;
        memset(iface, 0, strlen(buf) + 1);
        strncpy(iface, buf, strlen(buf));
    }

    /* test if rtap interface and try to find real interface */
    if (memcmp(iface, "rtap", 4) == 0 && dev->main_if == NULL)
    {
        memset(&ifr, 0, sizeof(ifr));
        strncpy(ifr.ifr_name, iface, sizeof(ifr.ifr_name) - 1);

        n = 0;

        if (ioctl(dev->fd_out, SIOCGIFINDEX, &ifr) < 0)
        {
            // create rtap interface
            n = 1;
        }

        net_ifaces = opendir("/sys/class/net");
        while (net_ifaces != NULL && (this_iface = readdir(net_ifaces)) != NULL)
        {
            if (this_iface->d_name[0] == '.')
                continue;

            char *new_r_file = (char *)realloc(
                r_file, (33 + strlen(this_iface->d_name) + 1) * sizeof(char));
            if (!new_r_file)
            {
                continue;
            }
            r_file = new_r_file;
            snprintf(r_file,
                     33 + strlen(this_iface->d_name) + 1,
                     "/sys/class/net/%s/device/rtap_iface",
                     this_iface->d_name);

            if ((acpi = fopen(r_file, "r")) == NULL)
                continue;
            dev->drivertype = DT_IPW2200;

            memset(buf, 0, 128);
            IGNORE_ZERO(fgets(buf, 128, acpi));
            if (n == 0) // interface exists
            {
                if (strncmp(buf, iface, 5) == 0)
                {
                    fclose(acpi);
                    acpi = NULL;
                    closedir(net_ifaces);
                    net_ifaces = NULL;
                    dev->main_if = (char *)malloc(strlen(this_iface->d_name) + 1);
                    if (dev->main_if == NULL)
                        continue;
                    strcpy(dev->main_if, this_iface->d_name);
                    break;
                }
            }
            else // need to create interface
            {
                if (strncmp(buf, "-1", 2) == 0)
                {
                    // repoen for writing
                    fclose(acpi);
                    if ((acpi = fopen(r_file, "w")) == NULL)
                        continue;
                    fputs("1", acpi);
                    // reopen for reading
                    fclose(acpi);
                    if ((acpi = fopen(r_file, "r")) == NULL)
                        continue;
                    IGNORE_ZERO(fgets(buf, 128, acpi));
                    if (strncmp(buf, iface, 5) == 0)
                    {
                        closedir(net_ifaces);
                        net_ifaces = NULL;
                        dev->main_if = (char *)malloc(strlen(this_iface->d_name) + 1);
                        if (dev->main_if == NULL)
                            continue;
                        strcpy(dev->main_if, this_iface->d_name);
                        fclose(acpi);
                        acpi = NULL;
                        break;
                    }
                }
            }
            fclose(acpi);
            acpi = NULL;
        }

        if (net_ifaces != NULL)
            closedir(net_ifaces);
    }

    if (openraw(dev, iface, dev->fd_out, &dev->arptype_out, dev->pl_mac) != 0)
    {
        goto close_out;
    }

    /* don't use the same file descriptor for in and out on bcm43xx,
       as you read from the interface, but write into a file in /sys/...
     */
    if (!(dev->drivertype == DT_BCM43XX) && !(dev->drivertype == DT_IPW2200))
    {
        close(dev->fd_in);
        dev->fd_in = dev->fd_out;
    }
    else
    {
        /* if bcm43xx or ipw2200, swap both fds */
        n = dev->fd_out;
        dev->fd_out = dev->fd_in;
        dev->fd_in = n;
    }

    dev->arptype_in = dev->arptype_out;

    if (iface_malloced)
        free(iface);
    if (iwpriv)
        free(iwpriv);
    if (r_file)
    {
        free(r_file);
    }
    return 0;
close_out:
    close(dev->fd_out);
    if (r_file)
    {
        free(r_file);
    }
close_in:
    close(dev->fd_in);
    if (acpi)
        fclose(acpi);
    if (iface_malloced)
        free(iface);
    if (iwpriv)
        free(iwpriv);
    return 1;
}

struct wif * wi_alloc(int sz)
{
	struct wif * wi;
	void * priv;

	/* Allocate wif & private state */
	wi = malloc(sizeof(*wi));
	if (!wi) return NULL;
	memset(wi, 0, sizeof(*wi));

	priv = malloc(sz);
	if (!priv)
	{
		free(wi);
		return NULL;
	}
	memset(priv, 0, sz);
	wi->wi_priv = priv;

	return wi;
}
struct wif *linux_open(char *iface)
{
    struct wif *wi;
    struct priv_linux *pl;

    if (iface == NULL || strlen(iface) >= IFNAMSIZ)
    {
        return NULL;
    }

    wi = wi_alloc(sizeof(*pl));
    if (!wi)
        return NULL;
    wi->wi_read = linux_read;
    wi->wi_write = linux_write;
    wi->wi_set_channel = linux_set_channel;
    wi->wi_get_channel = linux_get_channel;
    wi->wi_close = linux_close;
    wi->wi_fd = linux_fd;
    wi->wi_get_monitor = linux_get_monitor;

    if (do_linux_open(wi, iface))
    {
        do_free(wi);
        return NULL;
    }

    return wi;
}

struct wif *wi_open(char *iface)
{
    struct wif *wi;

    if (iface == NULL || iface[0] == 0)
    {
        return NULL;
    }

    wi = linux_open(iface);
    if (!wi)
        return NULL;

    strncpy(wi->wi_interface, iface, sizeof(wi->wi_interface) - 1);
    wi->wi_interface[sizeof(wi->wi_interface) - 1] = 0;

    return wi;
}