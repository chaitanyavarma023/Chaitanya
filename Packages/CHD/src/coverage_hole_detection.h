#ifndef COVERAGE_HOLE_DETECTION_H
#define COVERAGE_HOLE_DETECTION_H

// Struct to store client data for coverage hole detection
typedef struct {
    int rssi_data[31];         // RSSI measurements for the last 5 seconds (-90 to -60 dBm)
    int failed_packets;        // Number of packets below threshold
    float failed_percentage;   // Percentage of packets below threshold
    bool in_pre_alarm;         // Whether the client is in pre-coverage hole state
    bool in_coverage_hole;     // Whether the client is in a confirmed coverage hole
    bool is_mitigating;        // Whether mitigation has already been applied
} client_data_t;

// Struct to store AP configuration and state
typedef struct {
    int tx_power;              // Transmission power of the AP (in dBm)
    int channel;               // Channel number
    bool optimized_roaming_enabled; // Flag for Optimized Roaming
} AP;

void track_rssi(client_data_t *client, int new_rssi_value, int data_threshold, int voice_threshold);
void handle_coverage_hole_mitigation(client_data_t *client, AP *ap, int min_failed_client_count, float coverage_exception_level);
void requalify_and_increase_power(client_data_t *client, AP *ap);
void handle_optimized_roaming(client_data_t *client, AP *ap, int data_rssi_threshold);
void disassociate_client(client_data_t *client);
int calculate_average_rssi(int rssi_data[31]);

#endif
