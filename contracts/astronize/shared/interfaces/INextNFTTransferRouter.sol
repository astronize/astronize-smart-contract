
pragma solidity >=0.6.0;

interface INextNFTTransferRouter {
  function transferFromKAP721(
    string memory _project,
    address _token,
    address _sender,
    address _recipient,
    uint256 _tokenId
  ) external;
}