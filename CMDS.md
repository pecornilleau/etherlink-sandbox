# How to "by hand"

## Start the sequencer in sandbox mode

Prepare the sandbox kernel configuration
```
./octez-evm-node make kernel installer config installer_sandbox.yaml --bootstrap-account 0x6ce4d79d4e77402e1ef3417fdda433aa744c6e1c --chain-id 123123
```
Compile the kernel with debug info

```
make -f etherlink.mk EVM_KERNEL_FEATURES=debug build
```
Generate the kernel installer

```
./smart-rollup-installer get-reveal-installer -u evm_kernel.wasm -o installer.hex --setup-file installer_sandbox.yaml -P sequencer-sandbox-dir/wasm_2_0_0
```

Start the sequencer

```
./octez-evm-node run sandbox --data-dir sequencer-sandbox-dir --rpc-addr 0.0.0.0 --rpc-port 8545 --initial-kernel installer.hex --time-between-blocks none --private-rpc-port 8546 --cors-headers "*" --cors-origins "*"
```
As long as you keep the data-dir, you can reuse the same instance. The rpc-addr as 0.0.0.0 ensures docker can access it. The two cors configurations are necessary for metamask to access to the node. 

It won’t produce blocks automatically, to produce a block on demand:

```
curl -X POST -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"produceBlock"}'  http://localhost:8546/private
```
Note that there will be an error that the sequencer cannot inject its blueprint to the rollup node, which is expected in sandbox mode. It won’t prevent the sequencer from producing blocks, this error can be ignored.

## Metamask or you wallet of choice
The secret key used as bootstrap account is

```
 9722f6cc9ff938e63f8ccb74c3daa6b45837e5c5e3835ac08c44c50ab5f39dc0
```
Also add the custom network:
RPC: http://localhost:8545
Chain ID: 123123

## Blockscout
Follow the documentation basically. If you need to wipe the database:

```
docker compose up db -d
dropdb -p 7432 -h localhost -U blockscout blockscout
```
When asked for a password, use ceWb1MeLBEeOIfk65gU8EjF8 (you can also find it in the environment variables of the docker compose)
Rq: dropdb is included in the postgresql package of your distro
/!\ Don’t forget to disable the containers with

```
docker compose down
```
Otherwise they will be restarted with your computer.

To access the backend container

```
docker exec -it backend /bin/sh
```
/!\ if the kernel wasn’t always able to give the trace correctly, you probably need  to set the TRACE_FIRST_BLOCK
It seems that once blockscout manage to get an answer from the callTracer, it will try again old blocks. And will continue to try many times a second until a answer is given. 

Logs are in blockscout/docker-compose/services/logs/prod/

## Start an observer looking at mainnet

Get a snapshot:

```
wget https://snapshots.eu.tzinit.org/etherlink-mainnet/eth-mainnet.full
```
Build a rollup node directory from the snapshot (cannot be done by the evm node directly) :

```
octez-smart-rollup-node snapshot import eth-mainnet.full --data-dir rollup-node --no-check
```
Build an evm-node directory from the rollup node directory :

```
octez-evm-node init from rollup node rollup-node --data-dir observer --omit-delayed-tx-events

```
Start the observer without a rollup node
```
octez-evm-node run observer --dont-track-rollup-node --data-dir observer --evm-node-endpoint https://relay.mainnet.etherlink.com -K --rpc-addr 0.0.0.0 --rpc-port 8545 --cors-headers "*" --cors-origins "*"
```

After that, you can point a blockscout instance just like before. 
But you can also patch the observer with another kernel (after having killed the existing instance) :
```
octez-evm-node patch kernel with PATH_TO/evm_kernel.wasm --data-dir observer -f
```

Note: it’s probably better to let the observer keep up before patching (less stuff to reset if things go south).

Note: it’s probably a good idea to set the following variables in blockscout/docker-compose/envs/common-blockscout.env

```
FIRST_BLOCK=<block number of the patch>
TRACE_FIRST_BLOCK=<block number of the patch>
```

