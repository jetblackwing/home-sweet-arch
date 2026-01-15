#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>
#include <unistd.h>
#include <ctime>
#include <cstdio>
#include <array>

// Below constants can be adjusted as needed. I just wanted to test it quickly. 
const int TEMP_THRESHOLD = 40;  //b
const int BATTERY_CHECK_INTERVAL = 200; // seconds
const int TEMP_CHECK_INTERVAL = 5;     // seconds
const int FOLLOW_UP_DELAY = 6;        // 2 minutes

int get_battery_level() {
    std::ifstream file("/sys/class/power_supply/BAT0/capacity");
    if (file.is_open()) {
        int level;
        file >> level;
        return level;
    }
    return -1; // error
}

int get_cpu_temp() {
    std::ifstream file("/sys/class/thermal/thermal_zone0/temp");
    if (file.is_open()) {
        int temp_raw;
        file >> temp_raw;
        return temp_raw / 1000; // convert to Celsius
    }
    return -1; // error
}

std::string get_top_cpu_processes() {
    std::string result;
    FILE* pipe = popen("ps -eo cmd,%cpu --sort=-%cpu | sed '1d' | head -n 3", "r");
    if (!pipe) return "Unable to get process info";

    std::array<char, 128> buffer;
    while (fgets(buffer.data(), buffer.size(), pipe) != nullptr) {
        result += buffer.data();
    }
    pclose(pipe);
    return result;
}

void send_battery_warning(int level) {
    std::string cmd = "zenity --warning --title=\"You are now running on reserved battery power.\" "
                      "--text=\"Battery level is at " + std::to_string(level) + "%. Please connect your charger immediately to avoid shutdown.\" "
                      "--width=400 --height=200";
    system(cmd.c_str());
}

void send_overheat_warning(int temp) {
    std::string cmd = "notify-send --app-name=\"Thermal Monitor\" --urgency=critical "
                      "\"Warning: System Overheating\" "
                      "\"CPU temperature has reached " + std::to_string(temp) + "°C.\\n\\nTo prevent system instability or hardware damage, reduce system load or shut down the device immediately.\"";
    system(cmd.c_str());
}

void send_follow_up_overheat_warning(int temp, const std::string& processes) {
    std::string escaped_processes = processes;
    // Escape quotes for shell
    size_t pos = 0;
    while ((pos = escaped_processes.find('"', pos)) != std::string::npos) {
        escaped_processes.replace(pos, 1, "\\\"");
        pos += 2;
    }
    std::string cmd = "notify-send --app-name=\"Thermal Monitor\" --urgency=critical "
                      "\"Overheat Persisting\" "
                      "\"CPU temperature is still at " + std::to_string(temp) + "°C after 2 minutes.\\n\\nTop CPU-consuming processes:\\n" + escaped_processes + "\\n\\nPlease close these programs to reduce load.\"";
    system(cmd.c_str());
}

int main() {
    // Daemonize the process
    if (daemon(1, 0) == -1) {
        std::cerr << "Failed to daemonize" << std::endl;
        return 1;
    }

    bool battery_alerted = false;
    bool temp_alerted = false;
    bool follow_up_sent = false;
    time_t temp_alert_time = 0;
    time_t last_battery_check = time(nullptr);
    time_t last_temp_check = time(nullptr);

    while (true) {
        time_t now = time(nullptr);

        // Check battery every BATTERY_CHECK_INTERVAL seconds
        if (now - last_battery_check >= BATTERY_CHECK_INTERVAL) {
            int battery = get_battery_level();
            if (battery != -1) {
                if (battery <= BATTERY_THRESHOLD && !battery_alerted) {
                    send_battery_warning(battery);
                    battery_alerted = true;
                } else if (battery > BATTERY_THRESHOLD) {
                    battery_alerted = false; // reset if charged
                }
            }
            last_battery_check = now;
        }

        // Check temperature every TEMP_CHECK_INTERVAL seconds
        if (now - last_temp_check >= TEMP_CHECK_INTERVAL) {
            int temp = get_cpu_temp();
            if (temp != -1) {
                if (temp >= TEMP_THRESHOLD) {
                    if (!temp_alerted) {
                        send_overheat_warning(temp);
                        temp_alerted = true;
                        temp_alert_time = now;
                        follow_up_sent = false;
                    } else if (!follow_up_sent && (now - temp_alert_time >= FOLLOW_UP_DELAY)) {
                        std::string processes = get_top_cpu_processes();
                        send_follow_up_overheat_warning(temp, processes);
                        follow_up_sent = true;
                    }
                } else {
                    temp_alerted = false;
                    follow_up_sent = false;
                }
            }
            last_temp_check = now;
        }

        sleep(10); // sleep for 10 seconds before next check
    }

    return 0;
}