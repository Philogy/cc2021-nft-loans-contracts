const addresses = (val) => {
  if (val instanceof Array) return val.map((account) => account.address)
  return val.address
}

module.exports = { addresses }
