// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <1.0.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {
    event MemberAdded(address member);
    event MemberRemoved(address member);

    mapping(address => bool) private _members;

    /**
     * @dev A method to verify whether an address is a member of the whitelist
     * @param _account The address to verify.
     * @return Whether the address is a member of the whitelist.
     */
    function isMember(address _account) public view returns (bool) {
        return _members[_account];
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _account The member to add as a member.
     */
    function addMember(address _account) external onlyOwner {
        require(!isMember(_account), "Whitelist: Address is member already");

        _members[_account] = true;
        emit MemberAdded(_account);
    }

    /**
     * @dev A method to add a member to the whitelist
     * @param _accounts The _members to add as a member.
     */
    function addMembers(address[] calldata _accounts) external onlyOwner {
        uint256 l = _accounts.length;
        uint256 i;
        for (i; i < l; i++) {
            require(
                !isMember(_accounts[i]),
                "Whitelist: Address is member already"
            );

            _members[_accounts[i]] = true;
            emit MemberAdded(_accounts[i]);
        }
    }

    /**
     * @dev A method to remove a member from the whitelist
     * @param _account The member to remove as a member.
     */
    function removeMember(address _account) external onlyOwner {
        require(isMember(_account), "Whitelist: Not member of whitelist");

        delete _members[_account];
        emit MemberRemoved(_account);
    }

    /**
     * @dev A method to remove a _members from the whitelist
     * @param _accounts The _members to remove as a member.
     */
    function removeMembers(address[] calldata _accounts) external onlyOwner {
        uint256 l = _accounts.length;
        uint256 i;
        for (i; i < l; i++) {
            require(
                isMember(_accounts[i]),
                "Whitelist: Address is no member"
            );

            delete _members[_accounts[i]];
            emit MemberRemoved(_accounts[i]);
        }
    }
}