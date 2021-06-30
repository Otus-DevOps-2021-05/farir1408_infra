#!/bin/bash

sudo apt update && sudo apt install -y ruby-full ruby-bundler build-essential
echo "ruby version is:"
ruby -v
echo "bundler version is:"
bundler -v
