#!/bin/zsh
# Dev tool: record one scripted photo-auth walkthrough on an iOS simulator and cut stills.
#   walk.sh UDID SCENARIO OUT_PREFIX         (see walk_main.dart)
# Needs python3 + ffmpeg. Runs a debug build with `flutter run`; stops it after the closing flash.
U=$1; W=$2; P=$3
cd "$(dirname $0)/../.."
RAW=${TMPDIR:-/tmp}/pa_walk_raw.mov; LOG=${TMPDIR:-/tmp}/pa_walk.log
: > $LOG
xcrun simctl io $U recordVideo --codec h264 --force $RAW >/dev/null 2>&1 & REC=$!
sleep 2
flutter run -d $U -t tool/photo_auth/walk_main.dart --dart-define=WALK=$W --no-hot > $LOG 2>&1 &
FR=$!
until grep -q "MARK:flash_end" $LOG; do sleep 1; if ! kill -0 $FR 2>/dev/null; then break; fi; done
sleep 2; kill -INT $REC; wait $REC 2>/dev/null; sleep 1
kill $FR 2>/dev/null; xcrun simctl terminate $U com.eldermin.parentapp 2>/dev/null
python3 tool/photo_auth/cut_stills.py $RAW $LOG $P
cp $LOG ${P}_run.log
