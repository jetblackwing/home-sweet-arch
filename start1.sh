#!/bin/bash

# Wait a few seconds after login to ensure notification works
sleep 5

# Show notification
notify-send --app-name="tlp Power Monitor" "Severe Battery Degradation Detected" "The system has detected that your battery has degraded to 67% of its expected lifespan. Continued use may affect performance and safety. Immediate replacement is strongly recommended."

