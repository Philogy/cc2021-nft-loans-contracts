const { ethers } = require('hardhat')

async function main() {
  const [deployer] = await ethers.getSigners()
  const LoanTracker = await ethers.getContractFactory('VTLoanTracker')
  const AssetRegistry = await ethers.getContractFactory('AssetRegistry')
  const RightsRegistry = await ethers.getContractFactory('LoanRightsRegistry')

  const nextNonce = await ethers.provider.getTransactionCount(deployer.address)
  const loanTrackerAddr = ethers.utils.getContractAddress({
    from: deployer.address,
    nonce: nextNonce + 2
  })
  const assetRegistry = await AssetRegistry.deploy(loanTrackerAddr)
  const rightsRegistry = await RightsRegistry.deploy(loanTrackerAddr)
  const loanTracker = await LoanTracker.deploy(assetRegistry.address, rightsRegistry.address)

  console.log(`AssetRegistry deployed at ${assetRegistry.address}`)
  console.log(`RightsRegistry deployed at ${rightsRegistry.address}`)
  console.log(`LoanTracker deployed at ${loanTracker.address}`)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('err:', err)
    process.exit(1)
  })
