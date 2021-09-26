const { ethers } = require('hardhat')

async function main() {
  const ERC721 = await ethers.getContractFactory('MockERC721')
  const nft = await ERC721.deploy()
  console.log(`MockERC721 deployed at ${nft.address}`)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('err:', err)
    process.exit(1)
  })
