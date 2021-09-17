const InterestMaths = require('./interest-maths.js')

const constants = {
  Loan: {
    Status: {
      Uninitialized: 0,
      Open: 1,
      Defaulted: 2,
      PayedOff: 3
    },
    EraUnit: 43200 // 12 hours
  },
  InterestMaths: {
    SCALE: InterestMaths.SCALE
  }
}

module.exports = { constants, InterestMaths }
