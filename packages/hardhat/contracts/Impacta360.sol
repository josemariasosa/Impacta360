// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

struct Project {
    address owner;
    uint16 category;
    string description;
    string goal1;
    string goal2;
    string goal3;
}

contract Curator {
	mapping(address => bool) internal _curators;

	modifier onlyCurator {
		require(_curators[msg.sender], "Invalid Curator");
		_;
	}

	function isCurator(address _account) external view returns (bool) {
		return _curators[_account];
	}

	function _addCurator(address _account) internal {
        _curators[_account] = true;
    }

    function _removeCurator(address _account) internal {
        _curators[_account] = false;
    }
}

contract Impacta360 is Ownable, Curator {

    using SafeERC20 for IERC20;

    /// donationCategory
    /// 0 - environment
    /// 1 - education
    /// 2 - social

    uint16 constant public MAX_DONATION_CATEGORY = 3;

    uint256 private _lastProjectId;

    /// projectId => Project
    mapping(uint256 => Project) public projects;

    /// projectId => token => amount
    mapping(uint256 => mapping(address => uint256)) public balances;
    mapping(uint256 => mapping(address => uint256)) public withdrawOrder;

    /// token => 
    mapping(address => bool) public validTokens;

    event Donation(address indexed _donator, IERC20 indexed _token, uint256 _amount);
    event DonationInvoice(address indexed _donator, IERC20 indexed _token, uint256 _amount, string _invoiceData);
    event NewWithdrawOrder(address indexed _projectOwner, uint256 indexed _projectId, IERC20 indexed _token, uint256 _amount, string _achievement);
    event ReleasedFunds(address indexed _projectOwner, uint256 indexed _projectId, IERC20 indexed _token, uint256 _amount, string _evaluation);

    error NotProjectOwner(address _account);

    constructor(address _owner) {}

    /// *********
    /// * Owner *
    /// *********

    function addCurator(address _account) external onlyOwner {
        _addCurator(_account);
    }

    function removeCurator(address _account) external onlyOwner {
        _removeCurator(_account);
    }

    function addValidToken(IERC20 _token) external onlyOwner {
        validTokens[address(_token)] = true;
    }

    function removeValidToken(IERC20 _token) external onlyOwner {
        validTokens[address(_token)] = false;
    }

    /// ***********
    /// * Project *
    /// ***********

    function createProject(
        address _owner,
        string memory _description,
        uint16 _category,
        string memory goal1,
        string memory goal2,
        string memory goal3
    ) external {
        uint _id = _lastProjectId++;
        projects[_id] = Project(_owner, _category, _description, goal1, goal2, goal3);
    }

    function requestWithdraw(
        uint256 _projectId,
        IERC20 _token,
        uint256 _amount,
        string memory _achievement
    ) external {
        // Only project owner.
        Project memory project = projects[_projectId];
        if (msg.sender != project.owner) revert NotProjectOwner(msg.sender);
        withdrawOrder[_projectId][address(_token)] += _amount;

        emit NewWithdrawOrder(msg.sender, _projectId, _token, _amount, _achievement);
    }

    /// ************
    /// * Curators *
    /// ************

    function releaseFunds(
        uint256 _projectId,
        IERC20 _token,
        string memory _evaluation
    ) external onlyCurator {
        uint256 amountToRelease = withdrawOrder[_projectId][address(_token)];
        uint256 available = balances[_projectId][address(_token)];
        Project memory project = projects[_projectId];
        require(amountToRelease <= available, "NotEnoughBalance");

        _token.safeTransfer(project.owner, amountToRelease);
        emit ReleasedFunds(msg.sender, _projectId, _token, amountToRelease, _evaluation);
    }

    /// **********
    /// * Donate *
    /// **********

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
    /// ************
    /// * Internal *
    /// ************

    function _isValidDonation(IERC20 _token) private view {
        require(validTokens[address(_token)], "Invalid token");
    }

    function _inArray(uint256 _amount, uint256[4] memory _array) private pure returns (bool) {
        for (uint i; i < 4; i++) {
            if (_array[i] == _amount) return true;
        }
        return false;
    }
}