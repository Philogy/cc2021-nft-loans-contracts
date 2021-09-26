const { ethers } = require('hardhat')

async function main() {
  const [deployer] = await ethers.getSigners()
  const LoanTracker = await ethers.getContractFactory('VTLoanTracker')
  const AssetRegistry = await ethers.getContractFactory('AssetRegistry')
  const RightsRegistry = await ethers.getContractFactory('LoanRightsRegistry')
  const Weth = await ethers.getContractFactory('Weth')
  const ERC721Registrar = await ethers.getContractFactory('ERC721Registrar')
  const LoanManager = await ethers.getContractFactory('LoanManager')
  const ERC721 = await ethers.getContractFactory('MockERC721')

  const nextNonce = await ethers.provider.getTransactionCount(deployer.address)
  const loanTrackerAddr = ethers.utils.getContractAddress({
    from: deployer.address,
    nonce: nextNonce + 2
  })
  const assetRegistry = await AssetRegistry.deploy(loanTrackerAddr)
  const rightsRegistry = await RightsRegistry.deploy(loanTrackerAddr)
  const loanTracker = await LoanTracker.deploy(assetRegistry.address, rightsRegistry.address)
  const weth = await Weth.deploy()
  const nftRegistrar = await ERC721Registrar.deploy(assetRegistry.address)
  const loanManager = await LoanManager.deploy(
    loanTracker.address,
    rightsRegistry.address,
    assetRegistry.address,
    nftRegistrar.address,
    weth.address
  )
  const nft = await ERC721.deploy()

  console.log(`AssetRegistry deployed at ${assetRegistry.address}`)
  console.log(`RightsRegistry deployed at ${rightsRegistry.address}`)
  console.log(`LoanTracker deployed at ${loanTracker.address}`)
  console.log(`Weth deployed at ${weth.address}`)
  console.log(`ERC721Registrar deployed at ${nftRegistrar.address}`)
  console.log(`LoanManager deployed at ${loanManager.address}`)
  console.log(`MockERC721 deployed at ${nft.address}`)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('err:', err)
    process.exit(1)
  })
