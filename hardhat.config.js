require('@nomiclabs/hardhat-waffle')
require('hardhat-gas-reporter')

module.exports = {
  solidity: {
    version: '0.8.7',
    settings: {
      optimizer: {
        enabled: Boolean(process.env.OPTIMIZE_COMPILE),
        runs: 10000
      }
    }
  },
  gasReporter: {
    enabled: Boolean(process.env.REPORT_GAS)
  }
}
