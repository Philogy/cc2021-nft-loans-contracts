const addresses = (val) => {
  if (val instanceof Array) return val.map((account) => account.address)
  return val.address
}

const SAFE_TRANSFER_FROM = 'safeTransferFrom(address,address,uint256)'

module.exports = { addresses, SAFE_TRANSFER_FROM }
