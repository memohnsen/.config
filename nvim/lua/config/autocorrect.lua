local M = {}

M.words = {
  accomodate = 'accommodate',
  accomodated = 'accommodated',
  accomodates = 'accommodates',
  accomodating = 'accommodating',
  acheive = 'achieve',
  acheived = 'achieved',
  acheives = 'achieves',
  acheiving = 'achieving',
  acknowlege = 'acknowledge',
  acknowleged = 'acknowledged',
  acknowlegement = 'acknowledgment',
  activly = 'actively',
  allcoate = 'allocate',
  allcoated = 'allocated',
  allcoation = 'allocation',
  adress = 'address',
  adressed = 'addressed',
  adressing = 'addressing',
}

function M.setup()
  if vim.g.mm_autocorrect_loaded then
    return
  end

  vim.g.mm_autocorrect_loaded = true

  for bad, good in pairs(M.words) do
    vim.cmd(string.format('iabbrev %s %s', bad, good))
  end
end

return M
