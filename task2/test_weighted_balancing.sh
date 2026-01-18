#!/bin/bash
echo "=== Testing HAProxy Weighted Round Robin (2:3:4) ==="
echo "With domain example.local:"
for i in {1..9}; do
    echo "Request $i:"
    curl -s -H "Host: example.local" http://localhost:8888 | grep "<h1>"
done

echo -e "\n=== Without domain (expect 403) ==="
curl -i http://localhost:8888 2>&1 | head -n 1
