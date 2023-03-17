#!/bin/bash
GOOS=linux GOARCH=mipsle GOMIPS=softfloat go build -o main-mips -ldflags "-w -s" main.go
