#!/bin/sh

#  IsMainOn.command
#  StandUp
#
#  Created by Peter on 01/06/20.
#  Copyright © 2020 Peter. All rights reserved.
sudo -u $(whoami) ~/StandUp/BitcoinCore/$PREFIX/bin/bitcoin-cli -chain=main getblockchaininfo
exit 1
