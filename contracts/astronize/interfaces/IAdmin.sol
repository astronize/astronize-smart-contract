
pragma solidity 0.8.19;

interface IAdmin {
  function isSuperAdmin(address _addr) external view returns (bool);

  function isAdmin(address _addr) external view returns (bool);
}
