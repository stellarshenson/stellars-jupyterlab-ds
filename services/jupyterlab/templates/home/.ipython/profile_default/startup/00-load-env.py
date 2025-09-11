#!/usr/bin/env python3
"""
IPython startup script to copy environment from login bash shell
Place in: ~/.ipython/profile_default/startup/00-load-env.py
"""

import os
import subprocess

def load_login_shell_env():
    """Spawn login shell and copy its environment variables"""
    
    try:
        # Spawn login bash and get its environment
        result = subprocess.run(['bash', '-l', '-c', 'env'], 
                              capture_output=True, text=True, timeout=10)
        
        if result.returncode != 0:
            print(f"Failed to spawn login shell: {result.stderr.strip()}")
            return
        
        # Parse and overwrite environment variables
        vars_updated = 0
        for line in result.stdout.splitlines():
            if '=' in line:
                key, _, value = line.partition('=')
                if key:  # Skip empty keys
                    os.environ[key] = value
                    vars_updated += 1
        
        print(f"✓ Copied {vars_updated} environment variables from login shell")
        
    except subprocess.TimeoutExpired:
        print("Timeout spawning login shell")
    except Exception as e:
        print(f"Error copying login shell environment: {e}")

# Execute on kernel startup
load_login_shell_env()

# EOF
