#!/usr/bin/env python3
import re
import sys

def increment_version():
    try:
        # Read project.env
        with open('project.env', 'r') as f:
            lines = f.readlines()

        version = None
        version_line_idx = None

        # Find VERSION line
        for idx, line in enumerate(lines):
            if line.startswith('VERSION='):
                version = line.split('=', 1)[1].strip()
                # Strip quotes if present
                version = version.strip('"')
                version_line_idx = idx
                break

        if version is None:
            print('Error: VERSION not found in project.env')
            return 1

        # Parse and increment version
        match = re.match(r'^(\d+\.\d+\.)(\d+)(_.*)', version)

        if match:
            new_version = match.group(1) + str(int(match.group(2)) + 1) + match.group(3)

            # Update the VERSION line (keep quotes)
            lines[version_line_idx] = f'VERSION="{new_version}"\n'

            # Write back to project.env
            with open('project.env', 'w') as f:
                f.writelines(lines)

            print(f'Version updated: {version} -> {new_version}')
            return 0
        else:
            print(f'Error: Could not parse version {version}')
            return 1
    except Exception as e:
        print(f'Error: {e}')
        return 1

if __name__ == '__main__':
    sys.exit(increment_version())
