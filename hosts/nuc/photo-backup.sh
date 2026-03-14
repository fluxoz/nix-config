#!/usr/bin/env bash

zfs destroy -r storage/photos@7daysago
zfs rename -r storage/photos@6daysago @7daysago
zfs rename -r storage/photos@5daysago @6daysago
zfs rename -r storage/photos@4daysago @5daysago
zfs rename -r storage/photos@3daysago @4daysago
zfs rename -r storage/photos@2daysago @3daysago
zfs rename -r storage/photos@yesterday @2daysago
zfs rename -r storage/photos@today @yesterday
zfs snapshot -r storage/photos@today


