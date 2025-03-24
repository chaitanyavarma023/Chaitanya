
#ifndef INTERFACE_SETUP
#define INTERFACE_SETUP

#define MAX_IFACE_NAME 64

struct pcap_file_header
{
	uint32_t magic;
	uint16_t version_major;
	uint16_t version_minor;
	int32_t thiszone;
	uint32_t sigfigs;
	uint32_t snaplen;
	uint32_t linktype;
};

struct rx_info
{
	uint64_t ri_mactime;
	int32_t ri_power;
	int32_t ri_noise;
	uint32_t ri_channel;
	uint32_t ri_freq;
	uint32_t ri_rate;
	uint32_t ri_antenna;
};

struct tx_info
{
	uint32_t ti_rate;
};

struct wif *wi_open(char *iface);
int wi_get_monitor(struct wif *wi);

int wi_write(struct wif *wi,
			 struct timespec *ts,
			 int dlt,
			 unsigned char *h80211,
			 int len,
			 struct tx_info *ti);

int wi_read(struct wif *wi,
			struct timespec *ts,
			int *dlt,
			unsigned char *h80211,
			int len,
			struct rx_info *ri);

void wi_close(struct wif *wi);
char *wi_get_ifname(struct wif *wi);
int wi_get_channel(struct wif *wi);
void *wi_priv(struct wif *wi);
int wi_fd(struct wif * wi);

struct wif
{
	int (*wi_read)(struct wif *wi,
				   struct timespec *ts,
				   int *dlt,
				   unsigned char *h80211,
				   int len,
				   struct rx_info *ri);
	int (*wi_write)(struct wif *wi,
					struct timespec *ts,
					int dlt,
					unsigned char *h80211,
					int len,
					struct tx_info *ti);
	int (*wi_set_ht_channel)(struct wif *wi, int chan, unsigned int htval);
	int (*wi_set_channel)(struct wif *wi, int chan);
	int (*wi_get_channel)(struct wif *wi);
	void (*wi_close)(struct wif *wi);
	int (*wi_fd)(struct wif *wi);
	int (*wi_get_monitor)(struct wif *wi);

	void *wi_priv;
	char wi_interface[MAX_IFACE_NAME];
};

#define REQUIRE(c)                                             \
	do                                                         \
	{                                                          \
		if (!(c))                                              \
		{                                                      \
			fprintf(stderr, "Pre-condition Failed: %s\n", #c); \
			abort();                                           \
		}                                                      \
	} while (0)

#define IGNORE_NZ(c)                                      \
	do                                                    \
	{                                                     \
		int __rc = (c);                                   \
		if (__rc != 0)                                    \
		{                                                 \
			fprintf(stderr,                               \
					"%s:%d:Function failed(%d:%d): %s\n", \
					__FILE__,                             \
					__LINE__,                             \
					__rc,                                 \
					errno,                                \
					#c);                                  \
		}                                                 \
	} while (0)

#define IGNORE_ZERO(c)                                 \
	do                                                 \
	{                                                  \
		if ((c) == 0)                                  \
		{                                              \
			fprintf(stderr,                            \
					"%s:%d:Function failed(%d): %s\n", \
					__FILE__,                          \
					__LINE__,                          \
					errno,                             \
					#c);                               \
		}                                              \
	} while (0)

#define ALLEGE(c)                                                          \
	do                                                                     \
	{                                                                      \
		if (!(c))                                                          \
		{                                                                  \
			fprintf(stderr, "FAILED:%s:%d: %s\n", __FILE__, __LINE__, #c); \
			abort();                                                       \
		}                                                                  \
	} while (0)

#endif