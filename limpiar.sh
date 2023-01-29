#!/bin/bash
sudo apt autoremove -y
sudo apt clean
sudo find /var/log -type f -name "*.log" -mtime +7 -delete
sudo find /tmp -type f -mtime +7 -delete
