#!/bin/bash

# Compile
cd .. && ape compile

echo "--- Compilation from APE complete ---"

# Run static analysis
slither contracts

echo "--- Static Analysis from Slither complete ---"