//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

abstract contract Trust {
    uint blockNumberExpiration;
    address recipient;

    constructor(uint blockNumberExpiration_, address recipient_) {
        blockNumberExpiration = blockNumberExpiration_;
        recipient = recipient_;
    }

    function withdraw() public virtual;

    function _sendBalance() internal {
        payable(recipient).transfer(address(this).balance);
    }
}

// This version only lets the designated recipient withdraw, so they can keep it in the contract
//  longer than the block number.
contract RecipientTimedTrust is Trust {
    constructor(uint blockNumberExpiration_, address recipient_) Trust(blockNumberExpiration_, recipient_) { }
    
    function withdraw() public virtual override {
        if (msg.sender == recipient && block.number >= blockNumberExpiration) {
            super._sendBalance();
        }
    }
}

// This version lets anyone call withdraw but the funds still only go to the recipient. Means a
//  rando can force the recipient to receive the funds, but is also simpler - may be more futureproof;
//  no weird hacks around unexpected behaviour in the global msg object
contract PubliclyTimedTrust is Trust {
    constructor(uint blockNumberExpiration_, address recipient_) Trust(blockNumberExpiration_, recipient_) { }

    function withdraw() public virtual override {
        if (block.number >= blockNumberExpiration) {
            super._sendBalance();
        }
    }
}

// This version lets the deployer update the block number expiration. Useful for if changes to
//  Ethereum make blocks drastically longer or shorter. Of course, introduces another wrinkle
//  that may come with bugs or hackabilities.
abstract contract UpdateableTrust is Trust {
    address deployer;

    constructor(uint blockNumberExpiration_, address recipient_) Trust(blockNumberExpiration_, recipient_) {
        deployer = msg.sender;
    }

    function updateExpiration(uint newExpiration_) public {
        if (msg.sender == deployer) {
            blockNumberExpiration = newExpiration_;
        }
    }
}

// and of course, we can reimplement the above trusts to be updateable...
contract UpdateablePubliclyTimedTrust is UpdateableTrust {
    constructor(uint blockNumberExpiration_, address recipient_) UpdateableTrust(blockNumberExpiration_, recipient_) { }

    function withdraw() public virtual override {
        if (block.number >= blockNumberExpiration) {
            super._sendBalance();
        }
    }
}

contract UpdateableRecipientTimedTrust is UpdateableTrust {
    constructor(uint blockNumberExpiration_, address recipient_) UpdateableTrust(blockNumberExpiration_, recipient_) { }

    function withdraw() public virtual override {
        if (msg.sender == recipient && block.number >= blockNumberExpiration) {
            super._sendBalance();
        }
    }
}
