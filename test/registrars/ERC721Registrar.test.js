const { expect } = require('chai')
const { ethers } = require('hardhat')
const { SAFE_TRANSFER_FROM } = require('../utils')
const { constants, BigNumber: BN } = ethers

const TOTAL_MOCK_NFTS = 2

describe('ERC721Registrar', () => {
  let loanTracker
  let attacker
  let users
  let assetRegistry
  let nftRegistrar
  let mockRegistrar
  const mockNfts = []

  before(async () => {
    const AssetRegistry = await ethers.getContractFactory('AssetRegistry')
    const ERC721Registrar = await ethers.getContractFactory('ERC721Registrar')
    const MockAssetRegistrar = await ethers.getContractFactory('MockAssetRegistrar')
    const MockERC721 = await ethers.getContractFactory('MockERC721')

    ;[loanTracker, attacker, ...users] = await ethers.getSigners()
    assetRegistry = await AssetRegistry.deploy(loanTracker.address)
    nftRegistrar = await ERC721Registrar.deploy(assetRegistry.address)
    mockRegistrar = await MockAssetRegistrar.deploy(assetRegistry.address)

    for (let i = 0; i < TOTAL_MOCK_NFTS; i++) {
      mockNfts.push(await MockERC721.deploy())
    }
  })
  describe('receival & registration', () => {
    it('can receive ERC721 tokens', async () => {
      await mockNfts[0].mint(nftRegistrar.address, 13)
      await mockNfts[1].mint(users[0].address, 420)
      const userSendingNft = mockNfts[1].connect(users[0])
      await userSendingNft[SAFE_TRANSFER_FROM](users[0].address, nftRegistrar.address, 420)
    })
    it('registers received ERC721 tokens', async () => {
      const newTokenId = BN.from(ethers.utils.randomBytes(32))
      const assetId = 2
      await expect(mockNfts[0].connect(users[3]).mint(nftRegistrar.address, newTokenId))
        .to.emit(nftRegistrar, 'Registration')
        .withArgs(assetId, mockNfts[0].address, newTokenId, constants.AddressZero)
        .to.emit(assetRegistry, 'Registration')
        .withArgs(assetId, nftRegistrar.address)

      expect(await mockNfts[0].ownerOf(newTokenId)).to.equal(nftRegistrar.address)

      const storedToken = await nftRegistrar.tokenOf(assetId)
      expect(storedToken.collection).to.equal(mockNfts[0].address)
      expect(storedToken.id).to.equal(newTokenId)
    })
    it('registers tokens using assetId', async () => {
      expect(await assetRegistry.totalAssets()).to.equal(3)
      await mockRegistrar.registerAsset()
      const expectedAssetId = 4
      const nft = mockNfts[0]
      const tokenId = 25
      await expect(nft.mint(nftRegistrar.address, tokenId))
        .to.emit(assetRegistry, 'Registration')
        .withArgs(expectedAssetId, nftRegistrar.address)
        .to.emit(nftRegistrar, 'Registration')
        .withArgs(expectedAssetId, nft.address, tokenId, constants.AddressZero)
      const token = await nftRegistrar.tokenOf(expectedAssetId)
      expect(token.collection).to.equal(nft.address)
      expect(token.id).to.equal(tokenId)
    })
  })
  describe('release', async () => {
    it('only allows AssetRegistry to trigger release', async () => {
      const assetId = 0
      await expect(
        nftRegistrar.connect(attacker).releaseTo(assetId, attacker.address)
      ).to.be.revertedWith('ERC721Registrar: Not registry')

      const nft = mockNfts[0]
      const tokenId = 13
      expect(await nft.ownerOf(tokenId)).to.equal(nftRegistrar.address)
      const recipient = users[1].address
      await expect(assetRegistry.connect(users[0]).releaseAssetTo(assetId, recipient))
        .to.emit(nftRegistrar, 'Release')
        .withArgs(assetId, nft.address, tokenId, recipient)
        .to.emit(assetRegistry, 'AssetRelease')
        .withArgs(assetId, nftRegistrar.address, recipient)
        .to.emit(nft, 'Transfer')
        .withArgs(nftRegistrar.address, recipient, tokenId)
      expect(await nft.ownerOf(tokenId)).to.equal(recipient)
    })
    it('allows re-registration if released to NFT registrar', async () => {
      const assetId = 1
      const nft = mockNfts[1]
      const tokenId = 420
      const newAssetId = 5

      await expect(assetRegistry.connect(users[0]).releaseAssetTo(assetId, nftRegistrar.address))
        .to.emit(nftRegistrar, 'Release')
        .withArgs(assetId, nft.address, tokenId, nftRegistrar.address)
        .to.emit(assetRegistry, 'AssetRelease')
        .withArgs(assetId, nftRegistrar.address, nftRegistrar.address)
        .to.emit(nftRegistrar, 'Registration')
        .withArgs(newAssetId, nft.address, tokenId, nftRegistrar.address)
        .to.emit(assetRegistry, 'Registration')
        .withArgs(newAssetId, nftRegistrar.address)
    })
  })
})
