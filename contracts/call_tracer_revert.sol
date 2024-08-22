// SPDX-FileCopyrightText: 2024 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract SimpleContract {
    uint256 x;
    function setX(uint256 _x) public {
        x = _x;
    }
}

contract ErrorContract {
    function simpleRevert() public pure {
        revert("Error while calling SimpleRevert");
    }

    function outOfGas(address simple) public {
        (bool success, ) = simple.call{gas: 2000}(
            abi.encodeWithSignature("setX(uint256)", 5)
        );
        require(!success, "Call success with little gas limit");
    }

    function invalidOpcode() public pure {
        assembly {
            invalid()
        }
    }

    function requireFailed() public pure {
        require(false, "Error on ErrorContract");
    }

    function startTest() public {
        (bool successsr, ) = address(this).call(
            abi.encodeWithSignature("simpleRevert()")
        );
        require(!successsr, "Success");
        SimpleContract s = new SimpleContract();
        (bool successoog, ) = address(this).call(
            abi.encodeWithSignature("outOfGas(address)", address(s))
        );
        require(successoog, "Failure");
        (bool successio, ) = address(this).call{gas:2000}(
            abi.encodeWithSignature("invalidOpcode()")
        );
        require(!successio, "Success");
        (bool successreq, ) = address(this).call(
            abi.encodeWithSignature("requireFailed()")
        );
        require(!successreq, "Success");
    }
}
