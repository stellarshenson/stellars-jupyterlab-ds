#!/bin/bash
# ----------------------------------------------------------------------------------------
# Generates welcome message and welcome.html
# ----------------------------------------------------------------------------------------

# execute render-info.py script to display info box; the auth token is deliberately
# NOT passed - the banner lands in the container log (docker logs), which must not
# hold the password (it points at the .env key instead)
BUILD_NAME=$(cat /build-name.txt)
BUILD_DATE=$(cat /build-date.txt)

conda run -n base python /render-info.py "$LAB_NAME" "$BUILD_NAME" "$BUILD_DATE"


# EOF

