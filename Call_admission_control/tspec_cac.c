// Define the maximum available bandwidth for voice traffic in microseconds
#define MAX_AVAILABLE_BANDWIDTH 1000000  // Example: 1 second of airtime in microseconds (1 million µs)
u64 current_used_bandwidth = 0;  // Global variable to track the total medium time currently used by active voice calls

/*
 * Function to process a TSPEC (Traffic Specification) request for voice traffic.
 * This function implements Call Admission Control (CAC) to ensure that new traffic
 * does not degrade the quality of existing voice traffic by exceeding available bandwidth.
 */
int wmm_process_tspec(struct wmm_tspec_element *tspec)
{
    u64 medium_time;               // Calculated medium time for the new TSPEC
    unsigned int pps, duration;    // Packets-per-second and duration of the frame transmission
    unsigned int up, psb, dir, tid; // QoS parameters from TSPEC (User Priority, Power Save, Direction, Traffic Identifier)
    u16 val, surplus;              // Various fields like MSDU size and surplus bandwidth allowance

    // Parse TSPEC Information fields for User Priority, Power Save Bit, Direction, and Traffic Identifier
    up = (tspec->ts_info[1] >> 3) & 0x07;    // Extract User Priority
    psb = (tspec->ts_info[1] >> 2) & 0x01;   // Extract Power Save Bit (PSB)
    dir = (tspec->ts_info[0] >> 5) & 0x03;   // Extract Direction (uplink/downlink)
    tid = (tspec->ts_info[0] >> 1) & 0x0f;   // Extract Traffic Identifier (TID)

    // Print extracted TSPEC info for debugging purposes
    wpa_printf(MSG_DEBUG, "WMM: TS Info: UP=%d PSB=%d Direction=%d TID=%d", up, psb, dir, tid);

    // Get and print the nominal MSDU size (Maximum Service Data Unit)
    val = le_to_host16(tspec->nominal_msdu_size);
    wpa_printf(MSG_DEBUG, "WMM: Nominal MSDU Size: %d%s", val & 0x7fff, val & 0x8000 ? " (fixed)" : "");

    // Get and print the mean data rate (in bits per second)
    wpa_printf(MSG_DEBUG, "WMM: Mean Data Rate: %u bps", le_to_host32(tspec->mean_data_rate));

    // Get and print the minimum PHY rate (in bits per second)
    wpa_printf(MSG_DEBUG, "WMM: Minimum PHY Rate: %u bps", le_to_host32(tspec->minimum_phy_rate));

    // Get and print the surplus bandwidth allowance
    val = le_to_host16(tspec->surplus_bandwidth_allowance);
    wpa_printf(MSG_DEBUG, "WMM: Surplus Bandwidth Allowance: %u.%04u", val >> 13, 10000 * (val & 0x1fff) / 0x2000);

    // Validate nominal MSDU size (it cannot be zero)
    val = le_to_host16(tspec->nominal_msdu_size);
    if (val == 0) {
        wpa_printf(MSG_DEBUG, "WMM: Invalid Nominal MSDU Size (0)");
        return WMM_ADDTS_STATUS_INVALID_PARAMETERS;
    }

    // Calculate packets-per-second (pps) estimate
    // pps = (Mean Data Rate / 8) / Nominal MSDU Size, rounded up
    pps = ((le_to_host32(tspec->mean_data_rate) / 8) + val - 1) / val;
    wpa_printf(MSG_DEBUG, "WMM: Packets-per-second estimate for TSPEC: %d", pps);

    // Ensure the minimum PHY rate is sufficient (should be at least 1 Mbps)
    if (le_to_host32(tspec->minimum_phy_rate) < 1000000) {
        wpa_printf(MSG_DEBUG, "WMM: Too small Minimum PHY Rate");
        return WMM_ADDTS_STATUS_INVALID_PARAMETERS;
    }

    // Calculate the transmission duration for one MSDU (in microseconds)
    duration = (le_to_host16(tspec->nominal_msdu_size) & 0x7fff) * 8 /
               (le_to_host32(tspec->minimum_phy_rate) / 1000000) +
               50;  // Additional time for SIFS (Short Interframe Space) + ACK

    // Surplus bandwidth allowance is a binary fixed-point value
    // Ensure the surplus bandwidth allowance is greater than 1.0
    surplus = le_to_host16(tspec->surplus_bandwidth_allowance);
    if (surplus <= 0x2000) {
        wpa_printf(MSG_DEBUG, "WMM: Surplus Bandwidth Allowance not greater than unity");
        return WMM_ADDTS_STATUS_INVALID_PARAMETERS;
    }

    // Calculate the medium time required for the TSPEC request
    // medium_time = (Surplus Bandwidth Allowance) * (Packets-per-second) * (Duration)
    medium_time = (u64) surplus * pps * duration / 0x2000;
    wpa_printf(MSG_DEBUG, "WMM: Estimated medium time: %lu", (unsigned long) medium_time);

    // Call Admission Control (CAC): Check if we have enough bandwidth available
    if ((current_used_bandwidth + medium_time) > MAX_AVAILABLE_BANDWIDTH) {
        // If the total bandwidth (current + new request) exceeds available bandwidth, reject the TSPEC request
        wpa_printf(MSG_DEBUG, "WMM: Refuse TSPEC request, insufficient bandwidth");
        return WMM_ADDTS_STATUS_REFUSED;
    }

    // If the TSPEC request is accepted, add the medium time of this request to the used bandwidth
    current_used_bandwidth += medium_time;
    wpa_printf(MSG_DEBUG, "WMM: Updated current used bandwidth: %lu", (unsigned long) current_used_bandwidth);

    // Convert the calculated medium time to the format required by TSPEC (in 32-microsecond units)
    tspec->medium_time = host_to_le16(medium_time / 32);

    // Return status indicating that the TSPEC request has been successfully admitted
    return WMM_ADDTS_STATUS_ADMISSION_ACCEPTED;
}

/*
 * Function to release bandwidth when a voice call ends and its TSPEC is no longer active.
 * This updates the global current_used_bandwidth variable to reflect the available bandwidth.
 */
void wmm_release_tspec(u64 medium_time) {
    // Subtract the released medium time from the current used bandwidth
    if (medium_time > current_used_bandwidth) {
        current_used_bandwidth = 0;  // Prevent underflow: reset to 0 if medium_time exceeds current usage
    } else {
        current_used_bandwidth -= medium_time;
    }

    // Log the updated bandwidth usage
    wpa_printf(MSG_DEBUG, "WMM: Released medium time, updated bandwidth: %lu", (unsigned long) current_used_bandwidth);
}
