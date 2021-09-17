const { BigNumber: BN } = require('ethers')

const SCALE = 1e6
const BN_SCALE = BN.from(SCALE)

const toPerc = (x) => BN.from(Math.floor(x * SCALE))
const fmul = (x, y) => x.mul(y).div(BN_SCALE)
const fdiv = (x, y) => x.mul(BN_SCALE).div(y)
const fexp = (x, exp) => {
  let acc = BN_SCALE
  for (let i = 0; i < exp; i++) acc = acc.mul(x).div(BN_SCALE)
  return acc
}
const fiexp = (r, exp) => fexp(BN_SCALE.add(r), exp)

const accrueOnce = (amount, r, payment = 0) => {
  const interest = fmul(amount, r)
  return amount.add(interest).sub(payment)
}

const accrueMany = (amount, r, reps, payment = 0) => {
  for (let i = 0; i < reps; i++) {
    amount = accrueOnce(amount, r, payment)
  }
  return amount
}

module.exports = {
  SCALE,
  toPerc,
  fmul,
  fdiv,
  fexp,
  fiexp,
  accrue: { once: accrueOnce, many: accrueMany }
}
