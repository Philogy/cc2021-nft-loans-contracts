const { expect } = require('chai')
const { ethers } = require('hardhat')

const addresses = (val) => {
  if (val instanceof Array) return val.map((account) => account.address)
  return val.address
}

describe('LoanRightsRegistry', () => {
  let loanTracker
  let attacker
  let users
  let rightsRegistry

  const SAFE_TRANSFER_FROM = 'safeTransferFrom(address,address,uint256)'

  before(async () => {
    const LoanRightsRegistry = await ethers.getContractFactory('LoanRightsRegistry')
    ;[loanTracker, attacker, ...users] = await ethers.getSigners()
    rightsRegistry = await LoanRightsRegistry.connect(loanTracker).deploy(loanTracker.address)
  })

  describe('setup', () => {
    it('has correct metadata', async () => {
      expect(await rightsRegistry.name()).to.equal('Loan Rights Registry')
      expect(await rightsRegistry.symbol()).to.equal('LRR')
    })
    it('has no issued tokens', async () => {
      expect(await rightsRegistry.totalTokensIssued()).to.equal(0)
    })
    it('starts accounts with no token balance', async () => {
      expect(await rightsRegistry.balanceOf(users[0].address)).to.equal(0)
    })
  })

  describe('registration', () => {
    it('only allows LoanTracker to register', async () => {
      const [lender, borrower] = addresses(users)
      await expect(rightsRegistry.connect(attacker).register(lender, borrower)).to.be.revertedWith(
        'LLR: Not LoanTracker'
      )

      await expect(rightsRegistry.connect(loanTracker).register(lender, borrower))
        .to.emit(rightsRegistry, 'Registered')
        .withArgs(0, lender, borrower)
        .to.emit(rightsRegistry, 'Transfer')
        .withArgs(ethers.constants.AddressZero, lender, 0)
        .to.emit(rightsRegistry, 'Transfer')
        .withArgs(ethers.constants.AddressZero, borrower, 1)

      expect(await rightsRegistry.balanceOf(lender)).to.equal(1)
      expect(await rightsRegistry.balanceOf(borrower)).to.equal(1)
    })
    it('tracks rights token owners as lender / borrower', async () => {
      const [lender, borrower] = addresses(users)
      expect(await rightsRegistry.lenderOf(0)).to.equal(lender)
      expect(await rightsRegistry.isLenderOf(0, lender)).to.be.true
      expect(await rightsRegistry.borrowerOf(0)).to.equal(borrower)
      expect(await rightsRegistry.isBorrowerOf(0, borrower)).to.be.true

      await rightsRegistry.connect(users[1])[SAFE_TRANSFER_FROM](borrower, users[2].address, 1)
      expect(await rightsRegistry.borrowerOf(0)).to.equal(users[2].address)
      expect(await rightsRegistry.isBorrowerOf(0, users[2].address)).to.be.true
      await rightsRegistry.connect(users[2])[SAFE_TRANSFER_FROM](users[2].address, borrower, 1)
    })
    it('recognizes approved operators as lender / borrower', async () => {
      const [lender] = addresses(users)
      expect(await rightsRegistry.isLenderOf(0, users[3].address)).to.be.false
      await rightsRegistry.connect(users[0]).setApprovalForAll(users[3].address, true)
      expect(await rightsRegistry.isLenderOf(0, users[3].address)).to.be.true

      await rightsRegistry.connect(users[0])[SAFE_TRANSFER_FROM](lender, users[2].address, 0)
      expect(await rightsRegistry.isLenderOf(0, lender)).to.be.false
      expect(await rightsRegistry.isLenderOf(0, users[3].address)).to.be.false
    })
    it('keeps track of loanId over multiple registrations', async () => {
      const [lender, borrower] = addresses(users)
      for (let i = 1; i < 10; i++) {
        expect(await rightsRegistry.totalTokensIssued()).to.equal(i * 2)
        await expect(rightsRegistry.register(lender, borrower))
          .to.emit(rightsRegistry, 'Registered')
          .withArgs(i, lender, borrower)
          .to.emit(rightsRegistry, 'Transfer')
          .withArgs(ethers.constants.AddressZero, lender, i * 2)
          .to.emit(rightsRegistry, 'Transfer')
          .withArgs(ethers.constants.AddressZero, borrower, i * 2 + 1)
      }
    })
  })
  describe('deletion', () => {
    it('only allows loanTracker to delete borrower', async () => {
      await expect(rightsRegistry.connect(attacker).deleteBorrowerOf(0)).to.be.revertedWith(
        'LLR: Not LoanTracker'
      )
      await expect(rightsRegistry.deleteBorrowerOf(0))
        .to.emit(rightsRegistry, 'Transfer')
        .withArgs(users[1].address, ethers.constants.AddressZero, 1)
    })
    it('only allows loanTracker to delete lender', async () => {
      await expect(rightsRegistry.connect(attacker).deleteLenderOf(1)).to.be.revertedWith(
        'LLR: Not LoanTracker'
      )
      await expect(rightsRegistry.deleteLenderOf(1))
        .to.emit(rightsRegistry, 'Transfer')
        .withArgs(users[0].address, ethers.constants.AddressZero, 2)
    })
    it('reverts for queries of nonexistent tokens', async () => {
      await expect(rightsRegistry.borrowerOf(0)).to.be.revertedWith(
        'ERC721: owner query for nonexistent token'
      )
      await expect(rightsRegistry.lenderOf(1)).to.be.revertedWith(
        'ERC721: owner query for nonexistent token'
      )
    })
  })
})
