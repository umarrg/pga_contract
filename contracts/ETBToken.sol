

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ETB is ERC20 {

    constructor() ERC20("Eat The Blocks Token", "ETB") {
        _mint(msg.sender, 1000000 * (10 ** decimals()));
    }
}