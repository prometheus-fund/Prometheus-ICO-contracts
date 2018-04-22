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

import "github.com/JustFixMe/Prometheus-ICO-contracts/Contracts/PrometheusPreICO.sol";


contract PrometheusICO is OracliszedETHUSD {
	
	IPrometheusToken public token;
	
	uint public startTime;
	
	uint public endTime;
	
	uint256 internal softCap;
	
	uint256 internal tokensSold;
	
	mapping (address => uint256) internal spendWei;
	
	bool internal canReturn;
	
	
	function PrometheusICO(
		IPrometheusToken	_token,
		uint				_precision,
		uint				_priceInUSD,
		uint256				_softCap
	) OracliszedETHUSD(_precision, _priceInUSD) public payable {
		token		=	_token;
		softCap		=	_softCap * (10 ** uint256(_token.decimals()));
		
		canReturn	=	false;
	}
	
	
	function EndICO() public {
		require(msg.sender == owner);
		
		uint256 contract_balance = token.balanceOf(address(this));
		
		require( (endTime < now) || (contract_balance == 0) );
		
		if (tokensSold >= softCap) {
			if (address(this).balance > 0) {
				owner.transfer(address(this).balance);
			}
			
			if (contract_balance > 0) {
				token.ForceTransfer(ICOContract, contract_balance);
			}
		}
		else {
			canReturn = true;
		}
	}
	
	
	function returnTokens() public {
		require(canReturn);
		
		require(spendWei[msg.sender] > 0);
		
		this.transfer(msg.sender, spendWei[msg.sender]);
		
		spendWei[msg.sender] = 0;
		
		token.BurnTokens(msg.sender);
	}
	
	
	function _buy(
		address _buyer,
		uint256 _value
	) internal returns(uint256) {
		require( (now > startTime) && (now < endTime));
		
		uint256 contract_balance = token.balanceOf(this);
		
		require(contract_balance > 0);
		
		uint256 ammount = ( _value * (10 ** uint256(token.decimals())) ) / priceInWei;
		
		require(ammount > 0);
		
		if (ammount > contract_balance) {
			uint256 diff = (ammount - contract_balance) * priceInWei / (10 ** uint256(token.decimals()));
			
			require(diff < _value);
			
			ammount = contract_balance;
			
			_buyer.transfer(diff);
		}
		
		token.ForceTransfer(_buyer, ammount);
		
		buyedTokens[_buyer] = buyedTokens[_buyer] + ammount;
		tokensSold = tokensSold + ammount;
		
		emit TokenPurchase(_buyer, ammount);
		
		return ammount;
	}
	
	
	function () public payable {
		_buy(msg.sender, msg.value);
	}
	
	
	function buy() public payable returns(uint256) {
		uint256 ammount = _buy(msg.sender, msg.value);
		
		return ammount;
	}
	
	
	
	
}