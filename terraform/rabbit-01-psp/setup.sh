#!/usr/bin/env bash

set -e

echo '{"otp": "'$(op item get rabbit_01_psp_token --vault 66qfxcmgwlhutunx6slav6fyve --otp)'"}'

#echo "$OP_SESSION_my"
