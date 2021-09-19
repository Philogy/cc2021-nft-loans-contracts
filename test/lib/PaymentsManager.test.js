const { expect } = require('chai')
const { ethers } = require('hardhat')
const { toEther } = require('../utils')

describe('PaymentsManager', () => {
  let payments
  let token1, token2
  let user1, user2, users

  before(async () => {
    const PaymentsManager = await ethers.getContractFactory('MockPaymentsManager')
    const MockERC20 = await ethers.getContractFactory('MockERC20')
    payments = await PaymentsManager.deploy()
    ;[user1, user2, ...users] = await ethers.getSigners()
    token1 = await MockERC20.deploy()
    token2 = await MockERC20.deploy()
  })
  describe('initial conditions', () => {
    it('has nothing available', async () => {
      expect(await token1.balanceOf(payments.address)).to.equal(0)
      expect(await token2.balanceOf(payments.address)).to.equal(0)

      expect(await payments.getAvailable(token1.address)).to.equal(0)
      expect(await payments.getAvailable(token2.address)).to.equal(0)
    })
  })
  describe('balance detection and release', () => {
    let excess
    let deposit
    it('accounts excess balance as available', async () => {
      excess = toEther(12)
      await token1.mint(payments.address, excess)
      expect(await payments.getAvailable(token1.address)).to.equal(excess)
    })
    it('reduces available balance based on stored', async () => {
      const stored = toEther(2)
      await payments.setStoredBalance(token1.address, stored)
      expect(await payments.getAvailable(token1.address)).to.equal(excess.sub(stored))
      await payments.setStoredBalance(token1.address, 0)
    })
    it('discounts assigned amounts', async () => {
      deposit = toEther(4)
      await payments.assignAvailableTo(token1.address, deposit, user1.address)
      expect(await payments.pendingBalanceOf(token1.address, user1.address)).to.equal(deposit)
      expect(await payments.getAvailable(token1.address)).to.equal(excess.sub(deposit))
      expect(await payments.storedBalanceOf(token1.address)).to.equal(deposit)
    })
    it('accounts released amounts', async () => {
      const release = toEther(1.5)
      await payments.connect(user1).releasePendingBalance(token1.address, user1.address, release)
      deposit = deposit.sub(release)
      expect(await payments.pendingBalanceOf(token1.address, user1.address)).to.equal(deposit)
      expect(await payments.getAvailable(token1.address)).to.equal(excess.sub(deposit))
      expect(await payments.storedBalanceOf(token1.address)).to.equal(deposit)
    })
    it('discounts specific skim amount', async () => {
      const toWithdraw = toEther(3.5)
      await expect(() =>
        payments.skimTo(token1.address, toWithdraw, user1.address)
      ).to.changeTokenBalances(token1, [payments, user1], [toWithdraw.mul(-1), toWithdraw])
      excess = excess.sub(toWithdraw)
      expect(await payments.getAvailable(token1.address)).to.equal(excess.sub(deposit))
      expect(await payments.storedBalanceOf(token1.address)).to.equal(deposit)
    })
    it('discounts complete skim amount', async () => {
      const toWithdraw = await payments.getAvailable(token1.address)
      await expect(() => payments.skimAllTo(token1.address, user2.address)).to.changeTokenBalances(
        token1,
        [payments, user2],
        [toWithdraw.mul(-1), toWithdraw]
      )
      excess = excess.sub(toWithdraw)
      expect(await payments.getAvailable(token1.address)).to.equal(excess.sub(deposit))
      expect(await payments.storedBalanceOf(token1.address)).to.equal(deposit)
    })
    it('accounts tokens seperately', async () => {
      const newMint = toEther(4.5)
      await token2.mint(payments.address, newMint)
      expect(await payments.getAvailable(token1.address)).to.equal(excess.sub(deposit))
      expect(await payments.getAvailable(token2.address)).to.equal(newMint)
    })
  })
})
