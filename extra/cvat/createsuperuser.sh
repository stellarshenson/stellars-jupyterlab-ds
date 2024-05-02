#!/bin/sh
docker exec -it cvat_server /bin/bash -c "python3 ~/manage.py createsuperuser"

