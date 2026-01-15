#include <iostream>
#include <filesystem>
#include <vector>
#include <string>
#include <cstdlib>
#include <unistd.h>
#include <sys/stat.h>
#include <fstream>

namespace fs = std::filesystem;

bool is_executable(const fs::path& p) {
    struct stat st;
    if (stat(p.c_str(), &st) == 0) {
        return st.st_mode & S_IXUSR;
    }
    return false;
}

bool has_shebang(const fs::path& p) {
    std::ifstream file(p);
    if (file.is_open()) {
        std::string line;
        if (std::getline(file, line)) {
            return line.substr(0, 2) == "#!";
        }
    }
    return false;
}

bool is_script(const fs::path& p) {
    // Simple check: has shebang or is shell script
    return has_shebang(p);
}

int main(int argc, char* argv[]) {
    bool dry_run = false;
    bool auto_yes = false;
    std::string dir = ".";

    // Simple arg parsing
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-n" || arg == "--dry-run") {
            dry_run = true;
        } else if (arg == "-y" || arg == "--yes") {
            auto_yes = true;
        } else if (arg == "-h" || arg == "--help") {
            std::cout << "Usage: " << argv[0] << " [OPTIONS] [DIR]\n";
            std::cout << "Options:\n";
            std::cout << "  -n, --dry-run    Show what would be run, do not execute\n";
            std::cout << "  -y, --yes        Run without prompting\n";
            std::cout << "  -h, --help       Show this help\n";
            return 0;
        } else {
            dir = arg;
        }
    }

    if (!fs::exists(dir) || !fs::is_directory(dir)) {
        std::cerr << "Directory not found: " << dir << std::endl;
        return 2;
    }

    std::vector<fs::path> scripts;
    for (const auto& entry : fs::directory_iterator(dir)) {
        if (entry.is_regular_file() && is_executable(entry.path())) {
            // Skip self
            if (fs::equivalent(entry.path(), argv[0])) continue;
            if (is_script(entry.path())) {
                scripts.push_back(entry.path());
            }
        }
    }

    if (scripts.empty()) {
        std::cout << "No runnable scripts found in: " << dir << std::endl;
        return 0;
    }

    std::cout << "Found " << scripts.size() << " scripts to consider." << std::endl;

    int fail_count = 0;
    int succ_count = 0;

    for (const auto& script : scripts) {
        std::cout << "\n==> " << script << std::endl;
        if (dry_run) {
            std::cout << "[dry-run] Would execute: " << script << std::endl;
            continue;
        }

        if (!auto_yes) {
            std::cout << "Run this script? [y/N] ";
            std::string ans;
            std::getline(std::cin, ans);
            if (ans != "y" && ans != "Y" && ans != "yes" && ans != "Yes") {
                std::cout << "Skipping " << script << std::endl;
                continue;
            }
        }

        std::cout << "Running: " << script << std::endl;
        int rc = system(script.c_str());
        if (rc != 0) {
            std::cout << "Script exited with status " << rc << std::endl;
            ++fail_count;
        } else {
            std::cout << "Script completed: OK" << std::endl;
            ++succ_count;
        }
    }

    std::cout << "\nSummary: succeeded=" << succ_count << ", failed=" << fail_count << ", total=" << scripts.size() << std::endl;

    return fail_count > 0 ? 1 : 0;
}