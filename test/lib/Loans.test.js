const { expect } = require('chai')
const { ethers } = require('hardhat')
const { time: timeUtils } = require('../utils')
const {
  constants: { Loan },
  InterestMaths
} = require('../../src/utils.js')
const { toPerc } = InterestMaths

const toEther = (n) => ethers.utils.parseUnits(n.toString(), 'ether')

describe('Loans', () => {
  let loans

  before(async () => {
    const Loans = await ethers.getContractFactory('MockLoans')
    loans = await Loans.deploy()
  })
  describe('creation', () => {
    let duration
    let eraDuration
    let interestRate
    let startTime
    let outstanding
    let minPayment
    it('creates loan with .init()', async () => {
      duration = 10
      eraDuration = 1
      interestRate = 0.01
      startTime = 0
      outstanding = 100
      minPayment = 0
      await loans.createLoan(
        duration,
        eraDuration,
        toPerc(interestRate),
        startTime,
        toEther(outstanding),
        minPayment
      )
      expect(await loans.getMinPayment(0)).to.equal(minPayment)

      const loan = await loans.getLoan(0)
      expect(loan.status).to.equal(Loan.Status.Open)
      expect(loan.lastPayedEra).to.equal(0)
      expect(loan.duration).to.equal(duration)
      expect(loan.eraDuration).to.equal(eraDuration)
      expect(loan.interestRate).to.equal(toPerc(interestRate))
      expect(loan.startTime).to.equal(startTime)
      expect(loan.outstanding).to.equal(toEther(outstanding))
      expect(loan.minPayment).to.equal(minPayment)
    })
    it('disallows loans with a era duration of 0', async () => {
      await expect(
        loans.createLoan(
          duration,
          0,
          toPerc(interestRate),
          startTime,
          toEther(outstanding),
          minPayment
        )
      ).to.be.revertedWith('Loans: Era duration 0')
      await expect(
        loans.createLoan(duration, 0, toPerc(interestRate), startTime, 0, minPayment)
      ).to.be.revertedWith('Loans: Era duration 0')
      await expect(
        loans.createLoan(duration, eraDuration, toPerc(interestRate), startTime, 0, minPayment)
      ).to.be.revertedWith('Loans: No principal')
    })
  })
  describe('era progression', () => {
    const eraDuration = 1
    let loanId
    it('stays at zero until first full era has passed', async () => {
      expect(await loans.getCurrentEra(0, 0)).to.equal(0)
      const eraLength = eraDuration * Loan.EraUnit
      expect(await loans.getCurrentEra(0, eraLength - 1)).to.equal(0)
      expect(await loans.getCurrentEra(0, eraLength)).to.equal(1)
    })
    it('tracks era through time', async () => {
      const eraLength = eraDuration * Loan.EraUnit
      expect(await loans.getCurrentEra(0, eraLength * 2)).to.equal(2)
      expect(await loans.getCurrentEra(0, eraLength * 5)).to.equal(5)
      expect(await loans.getCurrentEra(0, eraLength * 6 - 1)).to.equal(5)
      expect(await loans.getCurrentEra(0, eraLength * 6)).to.equal(6)
    })
    it('accounts for alternative start and era duration', async () => {
      const altEraDuration = 4
      const shiftedStart = 23
      await loans.createLoan(10, altEraDuration, toPerc(0.01), shiftedStart, toEther(100), 0)
      loanId = 1
      expect(await loans.getMinPayment(loanId)).to.equal(0)

      const eraLength = altEraDuration * Loan.EraUnit
      expect(await loans.getCurrentEra(loanId, 0)).to.equal(0)
      expect(await loans.getCurrentEra(loanId, shiftedStart)).to.equal(0)
      expect(await loans.getCurrentEra(loanId, eraLength)).to.equal(0)
      expect(await loans.getCurrentEra(loanId, eraLength + shiftedStart - 1)).to.equal(0)
      expect(await loans.getCurrentEra(loanId, eraLength + shiftedStart)).to.equal(1)
      expect(await loans.getCurrentEra(loanId, eraLength * 3 + shiftedStart)).to.equal(3)
      expect(await loans.getCurrentEra(loanId, eraLength * 4 + shiftedStart - 1)).to.equal(3)
    })
  })
  describe('interest accrual and payment', () => {
    describe('no minimum payment', () => {
      let outstandingSoFar = toEther(100)
      const loanId = 0
      const interestRate = 0.01
      it('disallows paying current if no era has passed', async () => {
        await expect(loans.payCurrent(loanId, toEther(1))).to.be.revertedWith(
          'Loans: No current era to pay off'
        )
      })
      it('accrues interest with payNext', async () => {
        await loans.payNext(loanId, 0)
        let loan = await loans.getLoan(loanId)
        outstandingSoFar = InterestMaths.accrue.once(outstandingSoFar, toPerc(interestRate))
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(1)

        await loans.payNext(loanId, 0)
        await loans.payNext(loanId, 0)
        loan = await loans.getLoan(loanId)
        outstandingSoFar = InterestMaths.accrue.many(outstandingSoFar, toPerc(interestRate), 2)
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(3)
      })
      it('accrues interest with payDown', async () => {
        await loans.payDown(loanId, 0, 3)
        const loan = await loans.getLoan(loanId)
        outstandingSoFar = InterestMaths.accrue.many(outstandingSoFar, toPerc(interestRate), 3)
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(6)
      })
      it('accrues interest before payment in payNext', async () => {
        const payment = toEther(12)
        await loans.payNext(loanId, payment)

        const loan = await loans.getLoan(loanId)
        outstandingSoFar = InterestMaths.accrue.once(
          outstandingSoFar,
          toPerc(interestRate),
          payment
        )
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(7)
      })
      it('accrues interest before payment in payDown', async () => {
        const payment = toEther(20)
        const eras = 3
        await loans.payDown(loanId, payment, eras)

        const loan = await loans.getLoan(loanId)
        outstandingSoFar = InterestMaths.accrue.once(
          outstandingSoFar,
          toPerc(interestRate),
          payment
        )
        outstandingSoFar = InterestMaths.accrue.many(
          outstandingSoFar,
          toPerc(interestRate),
          eras - 1
        )
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(10)
      })
      it('accrues no interest if paying current', async () => {
        const payment = toEther(25)
        await loans.payCurrent(loanId, payment)
        const loan = await loans.getLoan(loanId)
        outstandingSoFar = outstandingSoFar.sub(payment)
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(10)
      })
    })
    describe('with minimum payment', () => {
      let outstandingSoFar = toEther(100)
      let era = 0
      const loanId = 2
      const interestRate = 0.01
      const minPayment = toEther(5)
      before(async () => {
        await loans.createLoan(20, 1, toPerc(interestRate), 0, outstandingSoFar, minPayment)
        expect(await loans.getMinPayment(loanId)).to.equal(minPayment)
      })
      it('can only payNext with at least minPayment', async () => {
        const justBelow = minPayment.sub(1)
        await expect(loans.payNext(loanId, 0)).to.be.revertedWith('Loans: Payment below min')
        await expect(loans.payNext(loanId, justBelow)).to.be.revertedWith(
          'Loans: Payment below min'
        )
        const payment = minPayment
        await loans.payNext(loanId, payment)
        const loan = await loans.getLoan(loanId)
        outstandingSoFar = InterestMaths.accrue.once(
          outstandingSoFar,
          toPerc(interestRate),
          payment
        )
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(++era)
      })
      it('can pay current with less than minimum', async () => {
        const payment = minPayment.sub(1)
        await loans.payCurrent(loanId, payment)
        const loan = await loans.getLoan(loanId)
        outstandingSoFar = outstandingSoFar.sub(payment)
        expect(loan.outstanding).to.equal(outstandingSoFar)
        expect(loan.lastPayedEra).to.equal(1)
      })
      it('only allows payDown if minPayment is provided per era', async () => {
        const eras = 3
        const minTotal = minPayment.mul(eras)
        await expect(loans.payDown(loanId, minTotal.sub(1), eras)).to.be.revertedWith(
          'Loans: Total payment below min'
        )
        await loans.payDown(loanId, minTotal, eras)
        outstandingSoFar = InterestMaths.accrue.many(
          outstandingSoFar,
          toPerc(interestRate),
          eras,
          minPayment
        )
        const loan = await loans.getLoan(loanId)
        expect(loan.outstanding).to.be.closeTo(outstandingSoFar, 10)
        expect(loan.lastPayedEra).to.equal((era += eras))
        outstandingSoFar = loan.outstanding
      })
      it('uses excess payDown for firstPayment', async () => {
        const eras = 4
        const extraPayment = toEther(3)
        const total = minPayment.mul(eras).add(extraPayment)
        await loans.payDown(loanId, total, eras)
        outstandingSoFar = InterestMaths.accrue.once(
          outstandingSoFar,
          toPerc(interestRate),
          extraPayment.add(minPayment)
        )
        outstandingSoFar = InterestMaths.accrue.many(
          outstandingSoFar,
          toPerc(interestRate),
          eras - 1,
          minPayment
        )
        const loan = await loans.getLoan(loanId)
        expect(loan.outstanding).to.be.closeTo(outstandingSoFar, 10)
        expect(loan.lastPayedEra).to.equal((era += eras))
        outstandingSoFar = loan.outstanding
      })
    })
  })
  describe('closing', () => {
    it('allows direct default while loan open', async () => {
      const loanId = 0
      await loans.setDefaulted(loanId)
      const loan = await loans.getLoan(loanId)
      expect(loan.status).to.equal(Loan.Status.Defaulted)
    })
    it('disallows setDefaulted, tryClose, tryDefault while not open', async () => {
      const loanId = 0
      await expect(loans.setDefaulted(loanId)).to.be.revertedWith('Loans: Not open')
      await expect(loans.tryClose(loanId)).to.be.revertedWith('Loans: Not open')
      const manyYears = timeUtils.duration.weeks(53 * 999)
      await expect(loans.tryDefault(loanId, manyYears)).to.be.revertedWith('Loans: Not open')
    })
    it('only allows closing once loan payed off', async () => {
      const loanId = 1
      await expect(loans.tryClose(loanId)).to.be.revertedWith('Loans: Loan not payed off')
      let loan = await loans.getLoan(loanId)
      const payoffPayment = InterestMaths.accrue.once(loan.outstanding, loan.interestRate)
      await loans.payNext(loanId, payoffPayment)
      loan = await loans.getLoan(loanId)
      expect(loan.outstanding).to.equal(0)

      const manyYears = timeUtils.duration.weeks(53 * 999)
      await expect(loans.tryDefault(loanId, manyYears)).to.be.revertedWith('Loans: Loan payed off')

      await loans.tryClose(loanId)
      loan = await loans.getLoan(loanId)
      expect(loan.status).to.equal(Loan.Status.PayedOff)
      await expect(loans.tryClose(loanId)).to.be.revertedWith('Loans: Not open')
    })
    describe('force defaulting', () => {
      it('allows if behind on payments', async () => {
        const loanId = 2
        let loan = await loans.getLoan(loanId)
        const eraLength = loan.eraDuration * Loan.EraUnit
        await loans.tryDefault(loanId, loan.startTime + eraLength * (loan.lastPayedEra + 1))
        loan = await loans.getLoan(loanId)
        expect(loan.status).to.equal(Loan.Status.Defaulted)
      })
      it('allows if loan past due', async () => {
        const loanId = 3
        const eras = 4
        const eraDuration = 1
        const eraLength = eraDuration * Loan.EraUnit
        const totalLength = eras * eraLength
        await loans.createLoan(eras, eraDuration, toPerc(0.01), 0, toEther(100), 0)
        await expect(loans.tryDefault(loanId, totalLength - 1)).to.be.revertedWith(
          'Loans: Nothing past due'
        )

        await loans.tryDefault(loanId, totalLength)
        const loan = await loans.getLoan(loanId)
        expect(loan.status).to.equal(Loan.Status.Defaulted)
      })
    })
  })
})
