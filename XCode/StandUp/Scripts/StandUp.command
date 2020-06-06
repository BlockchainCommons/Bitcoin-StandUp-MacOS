#!/bin/sh

#  StandUp.command
#  StandUp
#
#  Created by Peter on 07/11/19.
#  Copyright © 2019 Blockchain Commons, LLC

mkdir ~/StandUp

function installBitcoin () {

  echo "Creating ~/StandUp/BitcoinCore..."
  mkdir ~/StandUp/BitcoinCore

  echo "Downloading $SHA_URL"
  curl $SHA_URL -o ~/StandUp/BitcoinCore/SHA256SUMS.asc -s
  echo "Saved to ~/StandUp/BitcoinCore/SHA256SUMS.asc"

  echo "Downloading Laanwj PGP signature from https://bitcoincore.org/laanwj-releases.asc..."
  curl https://bitcoincore.org/laanwj-releases.asc -o ~/StandUp/BitcoinCore/laanwj-releases.asc -s
  echo "Saved to ~/StandUp/BitcoinCore/laanwj-releases.asc"
  
  echo "Downloading Bitcoin Core $VERSION from $MACOS_URL"
  cd ~/StandUp/BitcoinCore
  curl $MACOS_URL -o ~/StandUp/BitcoinCore/$BINARY_NAME --progress-bar

  echo "Checking sha256 checksums $BINARY_NAME against SHA256SUMS.asc"
  ACTUAL_SHA=$(shasum -a 256 $BINARY_NAME | awk '{print $1}')
  EXPECTED_SHA=$(grep osx64 SHA256SUMS.asc | awk '{print $1}')

  echo "See two signatures (they should match):"
  echo $ACTUAL_SHA
  echo $EXPECTED_SHA
  
  if [ "$ACTUAL_SHA" == "$EXPECTED_SHA" ]; then

    echo "Signatures match"
    echo "Unpacking $BINARY_NAME"
    tar -zxvf $BINARY_NAME

  else

    echo "Signatures do not match! Terminating..."
    exit 1
    
  fi
  
}

function configureBitcoin () {

  echo "Creating the following bitcoin.conf at: "$DATADIR"/bitcoin.conf:"
  echo "$CONF"

  if [ -d "$DATADIR" ]; then

    cd "$DATADIR"

  else

    mkdir "$DATADIR"
    cd "$DATADIR"

  fi

  echo "$CONF" > bitcoin.conf
  
}

function installTor () {

  echo "Installing tor..."
  sudo -u $(whoami) /usr/local/bin/brew install tor

  echo "Creating torrc file"
  cp /usr/local/etc/tor/torrc.sample /usr/local/etc/tor/torrc

  echo "Configuring tor v3 hidden service's"
  sed -i -e 's/#ControlPort 9051/ControlPort 9051/g' /usr/local/etc/tor/torrc
  sed -i -e 's/#CookieAuthentication 1/CookieAuthentication 1/g' /usr/local/etc/tor/torrc
  sed -i -e 's/## address y:z./## address y:z.\
  \
  HiddenServiceDir \/usr\/local\/var\/lib\/tor\/standup\/main\/\
  HiddenServiceVersion 3\
  HiddenServicePort 1309 127.0.0.1:8332\
  HiddenServiceDir \/usr\/local\/var\/lib\/tor\/standup\/test\/\
  HiddenServiceVersion 3\
  HiddenServicePort 1310 127.0.0.1:18332\
  HiddenServiceDir \/usr\/local\/var\/lib\/tor\/standup\/reg\/\
  HiddenServiceVersion 3\
  HiddenServicePort 1311 127.0.0.1:18443/g' /usr/local/etc/tor/torrc

  echo "Creating hidden service directories at /usr/local/var/lib/tor/standup"
  mkdir /usr/local/var/lib
  mkdir /usr/local/var/lib/tor
  mkdir /usr/local/var/lib/tor/standup
  mkdir /usr/local/var/lib/tor/standup/main
  mkdir /usr/local/var/lib/tor/standup/test
  mkdir /usr/local/var/lib/tor/standup/reg
  chmod 700 /usr/local/var/lib/tor/standup/main
  chmod 700 /usr/local/var/lib/tor/standup/test
  chmod 700 /usr/local/var/lib/tor/standup/reg

  echo "Congratulations you are now StoodUp!\nClick the back button if this screen does not dismiss automatically"
  echo "Starting Tor as a service (it will automatically start every time you turn on your computer).."
  sudo -u $(whoami) /usr/local/bin/brew services start tor
  exit 1
  
}

if ! [ -x "$(command -v bitcoind)" ]; then
  
  # Bitcoin is not installed, install it
  
  installBitcoin
  configureBitcoin
  installTor
  
else
  
  # Bitcoin is installed already but user may want to do a fresh install
  
  if [ "$IGNORE_EXISTING_BITCOIN" == "YES" ]; then
  
    # Bitcoin is already installed, install again
    
    installBitcoin
    configureBitcoin
    installTor
  
  else
  
    # Bitcoin is already installed, don't install again
    
    configureBitcoin
    installTor
    
  fi
  
fi
