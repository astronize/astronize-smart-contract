pragma solidity >=0.6.0;

interface IKYC {
  function kycsLevel(address _addr) external view returns (uint256);
}
