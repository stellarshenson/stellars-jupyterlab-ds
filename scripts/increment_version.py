#!/usr/bin/env python3
import json
import re
import sys

def increment_version():
    try:
        with open('project.json', 'r') as f:
            data = json.load(f)

        version = data['version']
        match = re.match(r'^(\d+\.\d+\.)(\d+)(_.*)', version)

        if match:
            new_version = match.group(1) + str(int(match.group(2)) + 1) + match.group(3)
            data['version'] = new_version

            with open('project.json', 'w') as f:
                json.dump(data, f, indent=2)
                f.write('\n')  # Add trailing newline

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
