
pragma solidity >=0.6.0;

interface INextTransferRouter {
  function transferFrom(
    string memory _project,
    address _token,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}
