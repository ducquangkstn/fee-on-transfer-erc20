const BN = web3.utils.BN;

function readArtifactSync (artifactsPath) {
  const fsExtra = require('fs-extra');
  if (!fsExtra.pathExistsSync(artifactsPath)) {
    throw `artifact not found ${artifactsPath}`;
  }
  return fsExtra.readJsonSync(artifactsPath);
}

function getTruffleContract (artifactsPath) {
  const artifact = readArtifactSync(artifactsPath);
  const TruffleContractFactory = require('@nomiclabs/truffle-contract');
  const Contract = TruffleContractFactory(artifact);
  Contract.setProvider(web3.currentProvider);
  return Contract;
}

const precisionUnits = new BN(10).pow(new BN(18));
const zeroBN = new BN(0);
const ethAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
const MaxUint256 = new BN(2).pow(new BN(256)).sub(new BN(1));

function assertEqual (val1, val2, errorStr) {
    assert(new BN(val1).should.be.a.bignumber.that.equals(new BN(val2)), errorStr);
  }

module.exports = {getTruffleContract, precisionUnits, zeroBN, ethAddress, MaxUint256, assertEqual};
