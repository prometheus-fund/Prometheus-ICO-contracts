//MIT License
//
//Copyright (c) 2018 Anatolii Eremin
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:

//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity ^0.4.21;

import "github.com/JustFixMe/Prometheus-ICO-contracts/Contracts/BasicDefs.sol";


contract PrometheusICO is ReturnableICO {
	
	function PrometheusICO(
		address             _token,
		address				_oracul,
		uint				_priceInUSD,
		uint256				_softCap,
		uint256				_bonusValue,
		uint8				_bonusPercentageOffset,
		uint				_returnPeriodDuration
	) ReturnableICO(msg.sender, _token, _oracul, _priceInUSD, _softCap, _bonusValue, _bonusPercentageOffset, _returnPeriodDuration) public {
		
	}
	
	function EndICO() public {
		require(msg.sender == owner);
		
		uint256 contract_balance = token.balanceOf(address(this));
		
		require( (endTime < now) || (contract_balance == 0) );
		
		if (endTime > now) {
			endTime = now;
		}
		
		if (tokensSold >= softCap) {
			if (address(this).balance > 0) {
				owner.transfer(address(this).balance);
			}
			
			if (contract_balance > 0) {
				token.BurnTokensFrom(address(this));
			}
			
			token.UnlockTokens();
			
			emit StausUpdate("ICO has been ended with success. Soft cap was reached.");
		}
		else {
			returnPeriodEndTime = now + returnPeriodDuration;
			
			emit StausUpdate("ICO has been ended with failure. Soft cap was not reached. Tokens can be returned.");
		}
	}
	
	
	function withdraw() public {
	
		require(msg.sender == owner);
		
		if (returnPeriodEndTime == 0) {
			require( (tokensSold >= softCap) && (now > endTime) );
		}
		else {
			require(now > returnPeriodEndTime);
		}
		
		owner.transfer(this.balance);
		
	}
	
}