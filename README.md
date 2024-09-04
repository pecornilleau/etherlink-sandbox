Provided as an example. It should work, at least it did for me at some point in
time :shrug:

Discoverability is not ideal but there's a README at least.

Also, if you want the raw commands, see [CMDS.md](./CMDS.md)

# Prerequisite

- docker, with the docker-compose plugin v2 (moderatly recent docker is fine)
- tezos/tezos somewhere (duh)
- Nice to use forge and cast. See https://book.getfoundry.sh/getting-started/installation

# tl;dr
Set `$TEZOS_DIR` in `.env`

To start evm node in sandbox node
```
./sandbox install
./sandbox up
```

To start blockscout
```
./indexer install
./indexer up
```

To start an observer targeting mainnet, do the observer setup then
```
./observer up
```

# setup

There is `.env` with the necessary variables. 
You need to indicate `$TEZOS_DIR`. 
You can set `$BLOCKSCOUT_DIR` if you already cloned somewhere.

So, first thing:
```
source .env
```

There is an option to either use a sandbox or an observer. You should probably 
have distincts instances of blockscout and tweak the scripts if you want both 
in same dir. Or clone this repo twice :shrug:

## blockscout

To install:
```
./indexer install
```

To run:
```
./indexer up
```
Then go to http://localhost for the front.


## Sandbox

The idea is to start a local chain from block 0 and trigger block production by
hand, and point a blockscout at it, to test a patched kernel or node on crafted
transactions. There is a faucet.

Create the initial kernel with faucet and da fees (default to kernel in `$TEZOS_DIR`):
```
./sandbox install [path/to/kernel.wasm]
```

Start your sandbox:
```
./sandbox up
```

Produce a few block:
```
./new_block
./new_block
```

Check everything went fine by checking the output:
```
cat stdout_sandbox
```

Start the indexer
```
./indexer up
```

Make sure the indexer indexes by visiting http://localhost

## Observer

The idea is to start an observer looking at mainnet, to point a blockscout 
instance on it and check a patched kernel or node.


First get a snapshot:
```
wget https://snapshots.eu.tzinit.org/etherlink-mainnet/eth-mainnet.full
```

Then build a rollup-node directory
```
$TEZOS_DIR/octez-smart-rollup-node snapshot import eth-mainnet.full --data-dir rollup-node-dir --no-check
```

Then build a sequencer directory from the rollup-directory
```
$TEZOS_DIR/octez-evm-node init from rollup node rollup-node --data-dir sequencer-observer-dir --omit-delayed-tx-events
```

Then start an observer without a rollup-node
```
$TEZOS_DIR/octez-evm-node run observer --dont-track-rollup-node --data-dir sequencer-observer-dir --evm-node-endpoint https://relay.mainnet.etherlink.com -K --rpc-addr 0.0.0.0 --rpc-port 8545 --initial-kernel installer.hex --time-between-blocks none --cors-headers "*" --cors-origins "*"
```
or
```
./observer up
```

Look at it go, catching up to mainnet:
```
tail -f stdout_observer
```

Start the indexer:
```
./indexer up
```

Look at it go, catching up to the node. You can visit http://localhost to see 
the frontend.


# How to

## some scripts for admin

We have a few scripts to use:
- `./indexer` for blockscout
    - `./indexer install` clones and very minimal configuration of blockscout
    - `./indexer up` (get everything up, not as a deamon)
    - `./indexer up -d` (to get it as a daemon)
    - `./indexer down`
    - `./indexer db` to raise up only the db as daemon (to clean it afterwards)
    - `./indexer clean` to clean the db (need to start only the db before)
- `./sandbox` for a node in sandbox mode
    - `./sandbox install` to create installer kernel (fetch the `evm_kernel.wasm` in `$TEZOS_DIR`, will be loaded on startup)
    - `./sandbox install path/to/kernel.wasm` to create installer from specified kernel
    - `./sandbox up`, rq: launch in background
    - `./sandbox up --verbose`, rq: launch in background, and very chatty
    - `./sandbox rup`, to kill existing sandbox and relaunch
    - `./sandbox down`
    - `./sandbox patch`
    - `./sandbox patch PATH/TO/kernel.wasm`
- `./observer` for a node in observer node (same cmd as sandbox)
- `./new_block` to make the sandbox produce a block
- `./make_kernel` to build a kernel in $TEZOS_DIR before doing a patch
- `./trace <0x...>` to query the node directly for the call trace of a particular transaction

## How to patch the kernel

Build the kernel in `$TEZOS_DIR`. The provided script builts it in debug mode.
```
./make_kernel
```

Patch the node (using `sandbox` or `observer`)
```
./sandbox down
./sandbox patch
```
The output tells you at which l2 block the patch is applied _in hex_

The kernel can also be given directly
```
./sandbox patch PATH/TO/kernel.wasm
```

/!\ you can patch an observer but make sure you know what kernel to use /!\

/!\ if the kernel is not compatible with mainnet, things will probably break /!\

## How to clean the indexer

If the DB need to be cleaned up to reset the indexer.

Stop it
```
./indexer down
```

Starts the db and drop its content
```
./indexer db
./indexer clean
./indexer down

```

## LOGS

Because stuff will go wrong.
For the node, see `./sequencer-sandbox-dir` or `./sequencer-observer-dir`.

Also, stdout is redirected to `./stdout_sandbox` or `./stdout_observer`

For blockscout, see `docker-compose/services/logs/prod` 

## Send tx

Use cast and forge. The `.env` can set up the rpc url and a keystore for the faucet (in `./wallet`). There is no password on the keystore. Or use a local keystore but make sure the env variables for cast in .env are commented.

See https://book.getfoundry.sh/reference/cast/cast-wallet

```
cast send <to> --value <amount>
forge create <PATH>:<CONTRACT>
cast send <CONTRACT> "toto()"
```

or use eth-cli

To compile contracts, can use solc but really only thing you need is foundry
```
solc --abi --evm-version shanghai --output-dir $WD/contracts --overwrite --bin <CONTRACT.SOL> 
```

# Faucet for sandbox

Address: `0x6ce4d79d4E77402e1ef3417Fdda433aA744C6e1c`

Private key: `9722f6cc9ff938e63f8ccb74c3daa6b45837e5c5e3835ac08c44c50ab5f39dc0`

# Frequent pbs

- If blockscout strats to act crazy, trying to trace transaction that it can't, 
then it might be a good idea to tell him to start tracing after a later block. 
To do that, open `blockscout/docker-compose/ens/common-blockscout.env` and edit
`TRACE_FIRST_BLOCK`

It's why the alias `conf` is defined in `.env`.


# TODOS

- make it easier to have several instances of blockscout to have both an observer and a sandbox setup
- cleanup utils
- make it easier to specify a kernel or node binary
