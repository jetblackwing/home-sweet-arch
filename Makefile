CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra

all: script_manager system_monitor

script_manager: script_manager.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

system_monitor: system_monitor.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

clean:
	rm -f script_manager system_monitor

.PHONY: all clean