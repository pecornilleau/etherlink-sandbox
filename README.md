# Prerequisite

- docker, with the docker-compose plugin v2 (moderatly recent docker is fine)
- tezos/tezos somewhere (duh)
- blockscout somewhere (duh) (can be in this directory)
```
    git clone --depth 1 https://github.com/blockscout/blockscout.git
```
- Nice to use forge and cast. See https://book.getfoundry.sh/getting-started/installation

# How to

There is `.env` with the necessary variables. 
You need to indicate `$TEZOS_DIR`. 
You can leave `$BLOCKSCOUT_DIR` if you cloned in the same dir.

So, first thing:
```
source .env
```

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
For the node, see `./sequencer-sandbox-dir`

Also, stdout is redirected to `./stdout_sandbox`
- idea: 
```
tail -f stdout_sandbox
```

For blockscout, see `docker-compose/services/logs/prod`
- idea: set up a link
```
ln -s $BLOCKSCOUT_DIR/docker_compose/service/logs/prod logs_blockscout
```

## Send tx

Use cast and forge. The `.env` set up the rpc url and a keystore for the faucet (in `./wallet`). There is no password on the keystore.

```
cast send <to> --value <amount>
forge create <PATH>:<CONTRACT>
cast send <CONTRACT> "toto()"
```

or use eth-cli

To compile contracts, can use solc but really only thing you need is foundry
solc --abi --evm-version shanghai --output-dir $WD/contracts --overwrite --bin <CONTRACT.SOL> 

# Variables to set

Not much. The CHAIN_ID is probably a good idea.
You can use `blockscout_init.patch`:
```
cp blockscout_init.patch $BLOCKSCOUT_DIR
cd $BLOCKSCOUT_DIR
git apply blockscout_init.patch
```
# Frequent pbs

- If blockscout strats to act crazy, trying to trace transaction that it can't, 
then it might be a good idea to tell him to start tracing after a later block. 
To do that, open `blockscout/docker-compose/ens/common-blockscout.env` and edit
`TRACE_FIRST_BLOCK`

It's why the alias `conf` is defined.

# Observer

## setup 

First get a snapshot:
```
wget https://snapshots.eu.tzinit.org/etherlink-mainnet/eth-mainnet.full
```

Then build a rollup-node directory
```
octez-smart-rollup-node snapshot import eth-mainnet.full --data-dir rollup-node-dir --no-check
```

Then build a sequencer directory from the rollup-directory
```
octez-evm-node init from rollup node rollup-node --data-dir sequencer-observer-dir --omit-delayed-tx-events
```

Then start an observer without a rollup-node
```
octez-evm-node run observer --dont-track-rollup-node --data-dir sequencer-observer-dir --evm-node-endpoint https://relay.mainnet.etherlink.com -K --rpc-addr 0.0.0.0 --rpc-port 8545 --initial-kernel installer.hex --time-between-blocks none --cors-headers "*" --cors-origins "*"
```
or
```
./observer up
```

## How to

Use the `observer` script, same commands: `up`, `down`, `patch`.

It targets mainnet, to change that edit `observer` and set another endpoint.
