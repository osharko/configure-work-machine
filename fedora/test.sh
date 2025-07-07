#!/bin/bash

for file in dnf.sh zsh.sh flatpak_and_service.sh node_java.sh; do
	chmod +x "$file"
	./"$file"
done
