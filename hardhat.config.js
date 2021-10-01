require('@nomiclabs/hardhat-waffle')
require('hardhat-gas-reporter')
require('dotenv').config()

module.exports = {
  networks: {
    local: {
      url: 'HTTP://127.0.0.1:8545',
      accounts: [process.env.PRIV_KEY_ACCOUNT0]
    },
    harmony: {
      url: 'https://api.harmony.one',
      accounts: [process.env.PRIV_KEY_ACCOUNT0]
    }
  },
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
