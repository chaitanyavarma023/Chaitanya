#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <unistd.h>

// Struct to store client data for coverage hole detection
typedef struct {
    int rssi_data[31];         // RSSI measurements for the last 5 seconds (-90 to -60 dBm)
    int failed_packets;        // Number of packets below threshold
    float failed_percentage;   // Percentage of packets below threshold
    bool in_pre_alarm;         // Whether the client is in pre-coverage hole state
    bool in_coverage_hole;     // Whether the client is in a confirmed coverage hole
    bool is_mitigating;        // Whether mitigation has already been applied
    int id;                    // Client identifier
} client_data_t;

// Struct to store AP configuration and state
typedef struct {
    int tx_power;              // Transmission power of the AP (in dBm)
    int channel;               // Channel number
    bool optimized_roaming_enabled; // Flag for Optimized Roaming
} AP;

// Function prototypes
void track_rssi(client_data_t *client, int new_rssi_value, int data_threshold, int voice_threshold);
void handle_coverage_hole_mitigation(client_data_t *client, AP *ap, int min_failed_client_count, float coverage_exception_level);
void requalify_and_increase_power(client_data_t *client, AP *ap);
void handle_optimized_roaming(client_data_t *client, AP *ap, int data_rssi_threshold);
void disassociate_client(client_data_t *client);
int calculate_average_rssi(int rssi_data[31]);
void log_info(const char *msg);

// Track RSSI and detect if a coverage hole is present
void track_rssi(client_data_t *client, int new_rssi_value, int data_threshold, int voice_threshold) {
    // Shift previous RSSI values to the left
    for (int i = 0; i < 30; i++) {
        client->rssi_data[i] = client->rssi_data[i + 1];
    }
    // Add new RSSI value to the array
    client->rssi_data[30] = new_rssi_value;
    
    // Count failed packets below threshold
    client->failed_packets = 0;
    for (int i = 0; i < 31; i++) {
        if (client->rssi_data[i] < data_threshold) {
            client->failed_packets++;
        }
    }

    // Calculate percentage of failed packets
    client->failed_percentage = ((float)client->failed_packets / 31) * 100;

    // Set pre-coverage hole state
    if (client->failed_percentage >= 50.0) {
        client->in_pre_alarm = true;
    }

    // Set coverage hole state if conditions are met
    if (client->failed_percentage >= 50.0 && !client->in_coverage_hole) {
        if (client->failed_packets >= 3) {
            client->in_coverage_hole = true;
        }
    }
}

// Mitigate the coverage hole by increasing the AP's transmission power
void handle_coverage_hole_mitigation(client_data_t *client, AP *ap, int min_failed_client_count, float coverage_exception_level) {
    if (client->in_coverage_hole && !client->is_mitigating) {
        if (client->failed_packets >= min_failed_client_count && client->failed_percentage >= coverage_exception_level) {
            ap->tx_power += 1;  // Increase power by one step (adjust as needed)
            client->is_mitigating = true;
            printf("Mitigating coverage hole by increasing TX power to %d dBm.\n", ap->tx_power);
        }
    }
}

// Requalify and increase power gradually
void requalify_and_increase_power(client_data_t *client, AP *ap) {
    if (client->in_coverage_hole && ap->tx_power < 30) {  // MAX_TX_POWER = 30
        ap->tx_power += 1;
        printf("Requalifying coverage hole, increasing TX power to %d dBm.\n", ap->tx_power);
    }
}

// Handle Optimized Roaming and disassociate clients
void handle_optimized_roaming(client_data_t *client, AP *ap, int data_rssi_threshold) {
    if (ap->optimized_roaming_enabled) {
        int avg_rssi = calculate_average_rssi(client->rssi_data);
        if (avg_rssi < data_rssi_threshold) {
            disassociate_client(client);
            printf("Optimized Roaming: Disassociating client with RSSI %d below threshold %d.\n", avg_rssi, data_rssi_threshold);
        }
    }
}

// Helper to calculate the average RSSI over the last 31 measurements
int calculate_average_rssi(int rssi_data[31]) {
    int sum = 0;
    for (int i = 0; i < 31; i++) {
        sum += rssi_data[i];
    }
    return sum / 31;
}

// Disassociate a client (e.g., by sending a deauth message)
void disassociate_client(client_data_t *client) {
    printf("Disassociating client %d due to poor RSSI.\n", client->id);
}

// Logging utility to print information
void log_info(const char *msg) {
    printf("[INFO] %s\n", msg);
}

#define DATA_RSSI_THRESHOLD -80
#define VOICE_RSSI_THRESHOLD -75
#define MIN_FAILED_CLIENT_COUNT 3
#define COVERAGE_EXCEPTION_LEVEL 25.0

int main() {
    // Initialize a sample AP
    AP ap = { .tx_power = 15, .channel = 6, .optimized_roaming_enabled = true };

    // Simulate a client that will go through coverage hole detection
    client_data_t client = { 0 };
    client.id = 1;
    client.in_pre_alarm = false;
    client.in_coverage_hole = false;
    client.is_mitigating = false;

    // Simulate receiving RSSI data for the client
    srand(time(NULL));  // Seed for random number generation

    // Simulate 100 RSSI readings for the client
    for (int i = 0; i < 100; i++) {
        // Simulate an RSSI value between -90 and -60 dBm
        int simulated_rssi = (rand() % 31) - 90;
        printf("Client %d: Received RSSI: %d dBm\n", client.id, simulated_rssi);

        // Track the RSSI value for the client
        track_rssi(&client, simulated_rssi, DATA_RSSI_THRESHOLD, VOICE_RSSI_THRESHOLD);

        // Print out the current state of the client (RSSI tracking info)
        printf("Client %d - Failed Packets: %d, Failed Packet Percentage: %.2f%%\n", 
               client.id, client.failed_packets, client.failed_percentage);

        // Handle coverage hole mitigation
        handle_coverage_hole_mitigation(&client, &ap, MIN_FAILED_CLIENT_COUNT, COVERAGE_EXCEPTION_LEVEL);

        // Requalify and apply power increase if necessary
        requalify_and_increase_power(&client, &ap);

        // Handle optimized roaming (e.g., disassociate client if RSSI is too low)
        handle_optimized_roaming(&client, &ap, DATA_RSSI_THRESHOLD);

        // Simulate a small delay to mimic real-time data collection (1 second)
        sleep(1);
    }

    return 0;
}
