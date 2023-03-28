// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";

contract SimpleNFT {
    using Strings for uint256; // associates the Strings library will all uint256s

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping(uint256 => address) private _owners;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => uint256) private _balances;

    string constant baseURL = "http://josephsupercomputerlaserwebsite.com/cat/";

    function mint(uint256 _tokenId) external {
        require(_owners[_tokenId] == address(0), "token ID already owned");
        require(_tokenId < 100, "token ID too large");
        emit Transfer(address(0), msg.sender, _tokenId);
        _owners[_tokenId] = msg.sender;
        _balances[msg.sender] += 1;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        require(_owners[_tokenId] != address(0), "no such token");
        return _owners[_tokenId];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        // check if the tokenId exists
        require(_owners[_tokenId] != address(0), "no such token");
        require(_owners[_tokenId] == _from, "you need to own the token");
        require(msg.sender == _from || _operators[_from][msg.sender], "only people who own the token can transfer");

        emit Transfer(_from, _to, _tokenId);
        // reset permissions after transfered
        _operators[_from][msg.sender] = false;
        _owners[_tokenId] = _to;

        _balances[_from] -= 1;
        _balances[_to] += 1;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        // check the tokenId exists
        require(_owners[_tokenId] != address(0), "token does not exists");

        return string(abi.encodePacked(baseURL, _tokenId.toString()));
    }

    /**
     * Approves all NFTs.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        _operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * Checks if approval for all NFTs has been granted for an address.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operators[_owner][_operator];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "can not ask bout zero address");
        return _balances[_owner];
    }
}
