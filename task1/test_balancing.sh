#!/bin/bash
echo "=== Testing HAProxy Round-robin Load Balancing ==="
for i in {1..8}; do
    echo "Request $i:"
    curl -s http://localhost:8888 | grep -E "<h1>|<p>"
    echo "---"
done
