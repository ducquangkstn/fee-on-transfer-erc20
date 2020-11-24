const {expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {zeroBN} = require('./helper.js');
const BN = web3.utils.BN;
const Helper = require('./helper.js');

const ERC20Extended1 = artifacts.require('ERC20Extended1');
const TestToken = artifacts.require('TestToken');
const UniswapV2Router02 = artifacts.require('UniswapV2Router02');
const UniswapV2Factory = Helper.getTruffleContract('./node_modules/@uniswap/v2-core/build/UniswapV2Factory.json');
const WETH9 = Helper.getTruffleContract('./node_modules/@uniswap/v2-periphery/build/WETH9.json');
const UniswapV2Pair = Helper.getTruffleContract('./node_modules/@uniswap/v2-core/build/UniswapV2Pair.json');

let uniswapFactory;
let normalToken;
let weth;
let router;

let feeTokens = [];

let trader;
let lqProvider;

contract('uniswap pair', function (accounts) {
  const defaultTxProperties = {
    from: accounts[0]
  };

  before('set up', async () => {
    lqProvider = accounts[0];
    trader = accounts[1];
    feeTokens.push(await ERC20Extended1.new('percentage fee token', 'fot1', new BN(10).pow(new BN(24))));

    uniswapFactory = await UniswapV2Factory.new(accounts[0], defaultTxProperties);
    weth = await WETH9.new(defaultTxProperties);

    router = await UniswapV2Router02.new(uniswapFactory.address, weth.address);

    normalToken = await TestToken.new('test token', 'tst', new BN(10).pow(new BN(24)));
  });

  describe('trade with ETH-token', async () => {
    let token;
    let pair;

    before('create Pair', async () => {
      token = feeTokens[0];
      await uniswapFactory.createPair(weth.address, token.address);
      let pairAddr = await uniswapFactory.getPair(weth.address, token.address);
      pair = await UniswapV2Pair.at(pairAddr);
    });

    it('addLiquidityETH', async () => {
      let tokenAmount = new BN(10).pow(new BN(18)).mul(new BN(4));
      let ethAmount = new BN(10).pow(new BN(16)).mul(new BN(1));
      await token.approve(router.address, Helper.MaxUint256);
      // add liquidity
      await router.addLiquidityETHSupportingFOTTokens(
        token.address,
        tokenAmount,
        tokenAmount,
        ethAmount,
        true,
        lqProvider,
        Helper.MaxUint256,
        {
          value: ethAmount,
          from: accounts[0]
        }
      );

      const expectedSupply = new BN(10).pow(new BN(17)).mul(new BN(2));
      Helper.assertEqual(await pair.totalSupply(), expectedSupply);
    });

    it('swapExactETHForTokens', async () => {
      const path = [weth.address, token.address];
      const areFOTToken = [false, true];
      const amountIn = new BN(10).pow(new BN(16)).mul(new BN(3));

      let amountQuery = await router.getAmountsOut(amountIn, path, trader, trader, areFOTToken);

      let balanceBefore = await token.balanceOf(trader);
      await router.swapExactETHForTokensSupportingFOTTokens(
        amountQuery.actualAmountOut,
        path,
        trader,
        areFOTToken,
        Helper.MaxUint256,
        {value: amountIn, from: trader}
      );
      Helper.assertEqual(await token.balanceOf(trader), balanceBefore.add(amountQuery.actualAmountOut));
    });

    it('swapExactTokensForETHSupportingFOTTokens', async () => {
      const path = [token.address, weth.address];
      const areFOTToken = [true, false];
      const amountIn = new BN(10).pow(new BN(16)).mul(new BN(3));

      let amountQuery = await router.getAmountsOut(amountIn, path, trader, trader, areFOTToken);
      // approve and transfer token to trader
      await token.transfer(trader, amountIn);
      await token.approve(router.address, Helper.MaxUint256, {from: trader});
      // swap and get amountOut
      let balanceBefore = await Helper.getBalancePromise(trader);
      await router.swapExactTokensForETHSupportingFOTTokens(
        amountIn,
        amountQuery.actualAmountOut,
        path,
        trader,
        areFOTToken,
        Helper.MaxUint256,
        {from: trader, gasPrice: new BN(0)}
      );
      Helper.assertEqual(await Helper.getBalancePromise(trader), balanceBefore.add(amountQuery.actualAmountOut));
    });

    it('removeLiquditiyETH', async () => {
      let lqTokenAmount = await pair.balanceOf(lqProvider);
      await pair.approve(router.address, Helper.MaxUint256);
      await router.removeLiquidityETHSupportingFOTTokens(
        token.address,
        lqTokenAmount,
        zeroBN,
        zeroBN,
        lqProvider,
        Helper.MaxUint256
      );
    });
  });

  describe('trade with normal token', async () => {
    let token;
    let pair;

    before('create Pair', async () => {
      token = feeTokens[0];
      await uniswapFactory.createPair(normalToken.address, token.address);
      let pairAddr = await uniswapFactory.getPair(normalToken.address, token.address);
      pair = await UniswapV2Pair.at(pairAddr);
    });

    it('addLiquidity', async () => {
      let tokenAmount = new BN(10).pow(new BN(18)).mul(new BN(4));
      let normalTokenAmount = new BN(10).pow(new BN(16)).mul(new BN(1));
      await token.approve(router.address, Helper.MaxUint256);
      await normalToken.approve(router.address, Helper.MaxUint256);
      // add liquidity
      await router.addLiquiditySupportingFOTTokens(
        [token.address, normalToken.address],
        [tokenAmount, normalTokenAmount],
        [tokenAmount, normalTokenAmount],
        [true, false],
        lqProvider,
        Helper.MaxUint256,
        {
          from: accounts[0]
        }
      );

      const expectedSupply = new BN(10).pow(new BN(17)).mul(new BN(2));
      Helper.assertEqual(await pair.totalSupply(), expectedSupply);
    });

    it('swap normal token -> fee token', async () => {
      /// swap from extract token
      const path = [normalToken.address, token.address];
      const areFOTToken = [false, true];
      const amountIn = new BN(10).pow(new BN(16)).mul(new BN(3));

      let amountQuery = await router.getAmountsOut(amountIn, path, trader, trader, areFOTToken);

      await normalToken.transfer(trader, amountIn);
      await normalToken.approve(router.address, Helper.MaxUint256, {from: trader});

      let balanceBefore = await token.balanceOf(trader);
      await router.swapExactTokensForTokensSupportingFOTTokens(
        amountIn,
        amountQuery.actualAmountOut,
        path,
        trader,
        areFOTToken,
        Helper.MaxUint256,
        {from: trader}
      );
      Helper.assertEqual(await token.balanceOf(trader), balanceBefore.add(amountQuery.actualAmountOut));
      /// swap to extract token
      const amountOut = new BN(10).pow(new BN(16)).mul(new BN(3));
      amountQuery = await router.getAmountsInSupportingFOTTokens(amountOut, path, trader, trader, areFOTToken);
      await normalToken.transfer(trader, amountQuery[0]);
      balanceBefore = await token.balanceOf(trader);
      await router.swapTokensForExactTokensSupportingFOTTokens(
        amountOut,
        amountQuery[0],
        path,
        trader,
        areFOTToken,
        Helper.MaxUint256,
        {from: trader}
      );
      Helper.assertEqual(await token.balanceOf(trader), balanceBefore.add(amountOut));
    });

    it('swap fee token -> normal token', async () => {
      /// swap from extract token
      const path = [token.address, normalToken.address];
      const areFOTToken = [true, false];
      const amountIn = new BN(10).pow(new BN(16)).mul(new BN(3));

      let amountQuery = await router.getAmountsOut(amountIn, path, trader, trader, areFOTToken);

      await token.transfer(trader, amountIn.mul(new BN(2)));
      await token.approve(router.address, Helper.MaxUint256, {from: trader});

      let balanceBefore = await normalToken.balanceOf(trader);
      await router.swapExactTokensForTokensSupportingFOTTokens(
        amountIn,
        amountQuery.actualAmountOut,
        path,
        trader,
        areFOTToken,
        Helper.MaxUint256,
        {from: trader}
      );
      Helper.assertEqual(await normalToken.balanceOf(trader), balanceBefore.add(amountQuery.actualAmountOut));
      /// swap to extract token
      const amountOut = new BN(10).pow(new BN(16)).mul(new BN(3));
      amountQuery = await router.getAmountsInSupportingFOTTokens(amountOut, path, trader, trader, areFOTToken);
      await token.transfer(trader, amountQuery[0].mul(new BN(2)));
      balanceBefore = await normalToken.balanceOf(trader);
      await router.swapTokensForExactTokensSupportingFOTTokens(
        amountOut,
        amountQuery[0],
        path,
        trader,
        areFOTToken,
        Helper.MaxUint256,
        {from: trader}
      );
      Helper.assertEqual(await normalToken.balanceOf(trader), balanceBefore.add(amountOut));
    });
  });
});
