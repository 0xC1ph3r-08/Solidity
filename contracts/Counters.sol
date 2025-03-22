
// SPDX-License-Identifier: MIT
pragma  solidity ^0.8.0;

library Counter {

  struct Counter {
    uint256 current; // default: 0
  }

  function next(Counter storage index)
    internal
    returns (uint256)
  {
    index.current += 1;
    return index.current;
  }
}