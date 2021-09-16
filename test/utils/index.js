const { network, ethers } = require('hardhat')

const seconds = (x) => x
const minutes = (x) => 60 * seconds(x)
const hours = (x) => 60 * minutes(x)
const days = (x) => 24 * hours(x)
const weeks = (x) => 7 * days(x)

const duration = { seconds, minutes, hours, days, weeks }

const time = {
  duration,
  latest: async () => {
    const blockNumber = await ethers.provider.getBlockNumber()
    const { timestamp } = await ethers.provider.getBlock(blockNumber)
    return timestamp
  },
  increaseBy: async (seconds) => {
    await network.provider.send('evm_increaseTime', [seconds])
    await network.provider.send('evm_mine')
  },
  increaseTo: async (timestamp) => {
    await network.provider.send('evm_setNextBlockTimestamp', [timestamp])
    await network.provider.send('evm_mine')
  }
}

const addresses = (val) => {
  if (val instanceof Array) return val.map((account) => account.address)
  return val.address
}

const SAFE_TRANSFER_FROM = 'safeTransferFrom(address,address,uint256)'

module.exports = { time, addresses, SAFE_TRANSFER_FROM }
