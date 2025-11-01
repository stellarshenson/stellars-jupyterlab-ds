#!/bin/bash
## Installs Anysphere Cursor AI Assistant

conda install -y --update-all -n base nodejs
conda run -n base curl https://cursor.com/install -fsS | bash

clear
echo -e "\033[32mAnysphere Cursor Installation Successful\033[0m"
echo ""
echo -e "Typical Usage:"
echo -e "1. Go to your project folder"
echo -e "2. Type '\033[36mcursor-agent\033[0m' to start working with Cursor"
echo -e "See: https://cursor.com/cli"
echo ""

# EOF
