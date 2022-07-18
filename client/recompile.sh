rm -r -d build
truffle compile
cp build/contracts/* ../web-service/src/contracts/
