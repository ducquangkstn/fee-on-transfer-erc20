const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const BN = web3.utils.BN;
const Helper = require('./helper.js');

const ERC20Extended1 = artifacts.require('ERC20Extended1');
const UniswapV2Router02 = artifacts.require('UniswapV2Router02');
const UniswapV2Factory = Helper.getTruffleContract('./node_modules/@uniswap/v2-core/build/UniswapV2Factory.json');
const WETH9 = Helper.getTruffleContract('./node_modules/@uniswap/v2-periphery/build/WETH9.json');

let uniswapFactory;
let token;
let weth;
let router;

let feeTokens = [];

contract('uniswap pair', function (accounts) {
  const defaultTxProperties = {
    from: accounts[0]
  };

  before('set up', async () => {
    feeTokens.push(await ERC20Extended1.new('percentage fee token', 'fot1', new BN(10).pow(new BN(24))));

    uniswapFactory = await UniswapV2Factory.new(accounts[0], defaultTxProperties);
    weth = await WETH9.new(defaultTxProperties);

    router = await UniswapV2Router02.new(uniswapFactory.address, weth.address);
  });

  it('addLiquidityETH', async () => {
    let token = feeTokens[0];
    let tokenAmount = new BN(10).pow(new BN(18)).mul(new BN(4));
    let ethAmount = new BN(10).pow(new BN(16)).mul(new BN(1));
    await token.approve(router.address, Helper.MaxUint256);
    // add liquidity 1:1
    await router.addLiquiditySupportingFOTTokens(
      token.address,
      tokenAmount,
      tokenAmount,
      ethAmount,
      accounts[0],
      Helper.MaxUint256,
      {
        value: ethAmount,
        from: accounts[0]
      }
    );

    let pairAddr = await uniswapFactory.getPair(weth.address, token.address);
    Helper.assertEqual(await pairAddr.totalSuppy(), new BN(10).pow(new BN(17)).mul(new BN(2)));
  });
});
