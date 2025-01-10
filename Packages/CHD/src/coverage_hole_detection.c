#include "coverage_hole_detection.h"
#include <stdio.h>
#include <stdbool.h>

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
