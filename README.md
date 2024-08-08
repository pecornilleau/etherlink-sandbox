# Prerequisite

- docker, with the docker-compose plugin v2 (moderatly recent docker is fine)
- tezos/tezos somewhere (duh)
- blockscout somewhere (duh) (can be in this directory)
    git clone --depth 1 https://github.com/blockscout/blockscout.git
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
    - `./indexer clean` to clean the db. Password is ceWb1MeLBEeOIfk65gU8EjF8
- `./sandbox` for the node
    - `./sandbox up`, rq: not a daemon
    - `./sandbox up --verbose`, rq: not a daemon, and very chatty
    - `./sandbox down`
    - `./sandbox patch`
- `./new_block` to make the sandbox produce a block
- `./make_installer` to create the installer for the first launch (set a faucet and da fees)
- `./make_kernel` to build a kernel in $TEZOS_DIR before doing a patch
- `./trace <0x...>` to query the node directly for the call trace of a particular transaction

## LOGS

Because stuff will go wrong.
For the node, see `./sequencer-sandbox-dir`
For blockscout, see `docker-compose/services/logs/prod`
idea: set up a link
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

