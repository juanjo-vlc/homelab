#!/bin/bash -e
echo "Starting..."
python3 manage.py migrate

if [ -n "$DEBUG" ]; then
  python3 manage.py runserver 0.0.0.0:8000
else
  python3 manage.py runserver 0.0.0.0:8000
fi
