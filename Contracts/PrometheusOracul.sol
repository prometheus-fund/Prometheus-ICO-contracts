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

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


contract PrometheusOracul is usingOraclize {
	address internal owner;
	
	bool internal isQueryStarted;
	bool internal isStopRequested;
	uint internal updateInterval;
	
	uint256 public unitPrice;
	
	uint8 public usdDecimals;
	
	uint public currentETHUSD;
	
	uint public lastUpdateTime;
	
	event ETHUSDRateUpdate(uint NewExchangeRate);
	
	
	function PrometheusOracul( uint8 _usdDecimals ) public payable {
		owner = msg.sender;
		
		isQueryStarted = false;
		isStopRequested = false;
		
		usdDecimals = _usdDecimals;
		
		UpdatePrice();
	}
	
	
	function _UpdateRequest(uint _delay) internal returns(bool) {
	
		if (oraclize_getPrice("URL") > address(this).balance) {
			return false;
		}
		else {
			if (_delay > 0) {
				oraclize_query(_delay, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
			}
			else {
				oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
			}
			return true;
		}
	}
	
	
	function UpdatePrice() public payable {
		
	    require(msg.sender == owner);
	    
        _UpdateRequest(0);
    }
	
	
	function StartUpdateQuery(uint _interval) public payable {
		require(msg.sender == owner);
		
		updateInterval = _interval;		
		isQueryStarted = true;
		
		if (!_UpdateRequest(_interval)) {
			revert();
		}
	}
	
	
	function StopUpdateQuery() public {
		require(msg.sender == owner);
		require(isQueryStarted);
		require(!isStopRequested);
		
		isStopRequested = true;
	}
	
	
	function __callback(bytes32 myid, string result) public {
		
		require (msg.sender == oraclize_cbAddress());
		
		currentETHUSD = parseInt(result, uint(usdDecimals));
		
		unitPrice = 1 ether / uint256(currentETHUSD);
		
		lastUpdateTime = now;
		
		emit ETHUSDRateUpdate(currentETHUSD);
		
		if (isQueryStarted) {
			if (!isStopRequested) {
				if (!_UpdateRequest(updateInterval)) {
					updateInterval = 0;
					isQueryStarted = false;
				}
			}
			else {
				updateInterval = 0;
				isStopRequested = false;
				isQueryStarted = false;
			}
		}
	}
	
}
