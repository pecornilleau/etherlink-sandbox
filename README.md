# Prerequisite

- docker, with the docker-compose plugin v2 (moderatly recent docker is fine)
- tezos/tezos somewhere (duh)
- Nice to use forge and cast. See https://book.getfoundry.sh/getting-started/installation

# How to

There is `.env` with the necessary variables. 
You need to indicate `$TEZOS_DIR`. 
You can set `$BLOCKSCOUT_DIR` if you already cloned somewhere.

So, first thing:
```
source .env
```

## setup

There is an option to either use a sandbox or an observer. You should probably have distincts instances of blockscout and tweak the scripts if you want both in same dir. Or clone this repo twice :shrug:

### blockscout

Clone blockscout
```
    git clone --depth 1 https://github.com/blockscout/blockscout.git
```

Patch it using `blockscout_init.patch`:
```
cp blockscout_init.patch $BLOCKSCOUT_DIR
cd $BLOCKSCOUT_DIR
git apply blockscout_init.patch
```

Optionnal: setup a link to access the logs easily
```
ln -s $BLOCKSCOUT_DIR/docker_compose/service/logs/prod logs_blockscout
```

### Sandbox

The idea is to start a local chain from block 0 and trigger block production by
hand, and point a blockscout at it, to test a patched kernel or node on crafted
transaction. There is a faucet.

Create the initial kernel with faucet and da fees:
```
./make_installer
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

### Observer

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

## some scripts for admin

We have a few scripts to use:
- `./indexer` for blockscout
    - `./indexer up` (get everything up, not as a deamon)
    - `./indexer up -d` (to get it as a daemon)
    - `./indexer down`
    - `./indexer db` to raise up only the db as daemon (to clean it afterwards)
    - `./indexer clean` to clean the db (need to start only the db before)
- `./sandbox` for a node in sandbox mode
    - `./sandbox up`, rq: launch in background
    - `./sandbox up --verbose`, rq: launch in background, and very chatty
    - `./sandbox down`
    - `./sandbox patch`
- `./observer` for a node in observer node
- `./new_block` to make the sandbox produce a block
- `./make_installer` to create the installer for the first launch (set a faucet and da fees)
- `./make_kernel` to build a kernel in $TEZOS_DIR before doing a patch
- `./trace <0x...>` to query the node directly for the call trace of a particular transaction

## LOGS

Because stuff will go wrong.
For the node, see `./sequencer-sandbox-dir` or `.sequencer-observer-dir`

Also, stdout is redirected to `./stdout_sandbox` or `./stdout_observer`

For blockscout, see `docker-compose/services/logs/prod`

## Send tx

Use cast and forge. The `.env` can set up the rpc url and a keystore for the faucet (in `./wallet`). There is no password on the keystore. Or use a local keystore (if you use a local keystore make sure the env variables for cast in .env are commented).

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
