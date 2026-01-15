CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra

all: script_manager

script_manager: script_manager.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

clean:
	rm -f script_manager

.PHONY: all clean