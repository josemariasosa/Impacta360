// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

struct Project {
    address owner;
    string description;
    uint16 category;
	string[] goals;
}

contract Curator {
	mapping(address => bool) internal _curators;

	modifier onlyCurator {
		require(_curators[msg.sender], "Invalid Curator");
		_;
	}

	function isCurator(address _account) external returns (bool) {
		return _curators[_account];
	}

	function _addCurator(_address)
}

contract Impacta360 is Ownable {

    using SafeERC20 for IERC20;

    /// donationCategory
    /// 0 - environment
    /// 1 - education
    /// 2 - social

	address public 

    uint16 constant public MAX_DONATION_CATEGORY = 3;

    uint256 private _lastProjectId;

    /// projectId => Project
    mapping(uint256 => Project) public projects;

    /// projectId => token => amount
    mapping(uint256 => mapping(address => uint256)) public balances;

    /// token => 
    mapping(address => bool) public validTokens;

    event Donation(address _donator, IERC20 _token, uint256 _amount);
    event DonationInvoice(address _donator, IERC20 _token, uint256 _amount, string _invoiceData);

    constructor(address _owner) Ownable(_owner) {}

    function addValidToken(IERC20 _token) external onlyOwner {
        validTokens[address(_token)] = true;
    }

    function removeValidToken(IERC20 _token) external onlyOwner {
        validTokens[address(_token)] = false;
    }

    function donate(IERC20 _token, uint256 _amount, uint256 _projectId) external {
        _isValidDonation(_token);

        _token.safeTransferFrom(msg.sender, address(this), _amount);
        balances[_projectId][address(_token)] += _amount;

        emit Donation(msg.sender, _token, _amount);
    }

    function donateEnteprise(
        IERC20 _token,
        uint256 _amount,
        uint256 _projectId,
        string memory _invoiceData

    ) external {
        _isValidDonation(_token);

        _token.safeTransferFrom(msg.sender, address(this), _amount);
        balances[_projectId][address(_token)] += _amount;

        emit DonationInvoice(msg.sender, _token, _amount, _invoiceData);
    }

    function _isValidDonation(IERC20 _token) private view {
        require(validTokens[address(_token)], "Invalid token");
    }

    function _inArray(uint256 _amount, uint256[4] memory _array) private pure returns (bool) {
        for (uint i; i < 4; i++) {
            if (_array[i] == _amount) return true;
        }
        return false;
    }

    function createProject(address _owner, string memory _description, uint16 _category) external {
        uint _id = _lastProjectId++;
        projects[_id] = Project(_owner, _description, _category);
    }

}