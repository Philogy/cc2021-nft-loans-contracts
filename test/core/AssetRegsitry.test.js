const { expect } = require('chai')
const { ethers } = require('hardhat')
const { constants } = ethers

describe('AssetRegistry', () => {
  let loanTracker
  let attacker
  let users
  let assetRegistry
  let mockRegistrar

  before(async () => {
    const AssetRegistry = await ethers.getContractFactory('AssetRegistry')
    const MockAssetRegistrar = await ethers.getContractFactory('MockAssetRegistrar')

    ;[loanTracker, attacker, ...users] = await ethers.getSigners()
    assetRegistry = await AssetRegistry.deploy(loanTracker.address)
    mockRegistrar = await MockAssetRegistrar.deploy(assetRegistry.address)
  })

  describe('setup', () => {
    it('starts totalAssets at 0', async () => {
      expect(await assetRegistry.totalAssets()).to.equal(0)
    })
    it('leaves assetId data empty', async () => {
      expect(await assetRegistry.registrarOf(0)).to.equal(constants.AddressZero)
      expect(await assetRegistry.reserved(0)).to.equal(false)
    })
  })

  describe('registration', () => {
    it('allows any address to register assets', async () => {
      await expect(assetRegistry.connect(users[0]).registerAsset())
        .to.emit(assetRegistry, 'Registration')
        .withArgs(0, users[0].address)
      expect(await assetRegistry.registrarOf(0)).to.equal(users[0].address)
      await expect(assetRegistry.connect(users[1]).registerAsset())
        .to.emit(assetRegistry, 'Registration')
        .withArgs(1, users[1].address)
      expect(await assetRegistry.registrarOf(1)).to.equal(users[1].address)
    })
    it('returns correct assetId upon registration', async () => {
      await expect(mockRegistrar.registerAsset()).to.emit(mockRegistrar, 'NewAssetId').withArgs(2)
      expect(await assetRegistry.registrarOf(2)).to.equal(mockRegistrar.address)
    })
    it('updates totalAssets after new registrations', async () => {
      expect(await assetRegistry.totalAssets()).to.equal(3)
    })
  })

  describe('release', () => {
    it('only allows loan tracker to release a reserved asset', async () => {
      const assetId = 2
      await assetRegistry.reserve(assetId)
      await expect(
        assetRegistry.connect(attacker).releaseAssetTo(assetId, attacker.address)
      ).to.be.revertedWith('AssetRegistry: Not LoanTracker')

      const recipient = users[0].address
      await expect(assetRegistry.releaseAssetTo(assetId, recipient))
        .to.emit(assetRegistry, 'AssetRelease')
        .withArgs(assetId, mockRegistrar.address, recipient)
        .to.emit(mockRegistrar, 'ReleaseHook')
        .withArgs(assetId, recipient)
    })
    it('deletes data from registry after release', async () => {
      const assetId = 2
      expect(await assetRegistry.registrarOf(assetId)).to.equal(constants.AddressZero)
      expect(await assetRegistry.reserved(assetId)).to.equal(false)
    })
    it('allows anyone to release unreserved assets', async () => {
      await mockRegistrar.registerAsset()
      const assetId = 3
      const recipient = users[1].address
      await expect(assetRegistry.connect(users[1]).releaseAssetTo(assetId, recipient))
        .to.emit(assetRegistry, 'AssetRelease')
        .withArgs(assetId, mockRegistrar.address, recipient)
        .to.emit(mockRegistrar, 'ReleaseHook')
        .withArgs(assetId, recipient)
    })
    it('prevents release of nonexistent asset', async () => {
      const assetId = 420
      await expect(
        assetRegistry.connect(attacker).releaseAssetTo(assetId, attacker.address)
      ).to.be.revertedWith('AssetRegistry: Invalid asset')
    })
  })

  describe('reserving', () => {
    before(async () => {
      await mockRegistrar.registerAsset()
    })
    it('only allows loan tracker to reserve asset', async () => {
      const assetId = 4
      await expect(assetRegistry.connect(attacker).reserve(assetId)).to.be.revertedWith(
        'AssetRegistry: Not LoanTracker'
      )

      await expect(assetRegistry.reserve(assetId))
        .to.emit(assetRegistry, 'Reserved')
        .withArgs(assetId)
      expect(await assetRegistry.reserved(assetId)).to.equal(true)
    })
    it('prevents reserved asset from being re-reserved', async () => {
      const assetId = 4
      await expect(assetRegistry.reserve(assetId)).to.be.revertedWith(
        'AssetRegistry: Already reserved'
      )
    })
    it('prevents released asset to be reserved', async () => {
      await mockRegistrar.registerAsset()
      const assetId = 5
      await assetRegistry.connect(users[0]).releaseAssetTo(assetId, users[0].address)
      await expect(assetRegistry.reserve(assetId)).to.be.revertedWith(
        'AssetRegistry: Invalid asset'
      )
    })
  })
})
