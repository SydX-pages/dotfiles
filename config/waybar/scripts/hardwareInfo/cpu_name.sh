#!/bin/bash


echo "  $(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')"

