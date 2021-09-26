const { ethers } = require('hardhat')

async function main() {
  const Weth = await ethers.getContractFactory('Weth')
  const weth = await Weth.deploy()
  console.log(`Weth deployed at ${weth.address}`)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('err:', err)
    process.exit(1)
  })
