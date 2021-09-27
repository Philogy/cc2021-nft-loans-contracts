const { ethers } = require('hardhat')

async function main() {
  const ERC20Factory = await ethers.getContractFactory('ERC20Factory')
  const tokenFactory = await ERC20Factory.deploy()
  console.log(`ERC20Factory deployed at ${tokenFactory.address}`)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('err:', err)
    process.exit(1)
  })
