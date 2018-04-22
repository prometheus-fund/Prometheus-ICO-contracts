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


interface IPrometheusToken {
	function decimals() external view returns(uint8);
	function balanceOf(address) external view returns(uint256);
	function preICOContract() external view returns(address);
	function ICOContract() external view returns(address);
	function ForceTransfer(address _to, uint256 _value) external;
	function UnlockTokens() external;
	function BurnTokens() external;
}


contract Owned {
	address internal owner;
	
	function Owned() public {
		owner = msg.sender;
	}
}


contract ERC20Token {
	//Full name of token
	string public name;
	//Short name of token
	string public symbol;
	//Number of digits
	uint8 public decimals;
	//Total ammount of tokens
    uint256 public totalSupply;
	//Balances of token holders
	mapping (address => uint256) public balanceOf;
	//
	mapping (address => mapping(address => uint256)) public allowance;
	
	
	event Transfer( address indexed from, address indexed to, uint256 value );	
	event Approval( address indexed owner, address indexed spender, uint256 value );
	
	
	function transfer(address _spender, uint256 _value) public;
	
	function transferFrom( address _from, address _to, uint256 _value ) public;
	
	function approve( address _to, uint256 _value ) public;
	
	
	function ERC20Token(
		string _name,
		string _symbol,
		uint8 _decimals,
		uint256 _totalSupply
	) public {		
		name			=	_name;
		symbol			=	_symbol;
		decimals		=	_decimals;
		totalSupply		=	_totalSupply * (10 ** _decimals);
	}
	
	//
	function _transfer(
		address _from,
		address _to,
		uint256 _value
	) internal {
        
        require(_to != 0x0);
        
        require(_value > 0);
        
        require(balanceOf[_from] >= _value);
        
        balanceOf[_from] -= _value;
		
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
    }
	
	
}


contract OracliszedETHUSD is Owned, usingOraclize {
	uint256 internal priceInWei;
	
	uint public priceInUSD;
	
	uint public precision;
	
	uint public currentETHUSD;
	
	uint public lastUpdateTime;
	
	event ETHUSDRateUpdate(uint NewETHUSDRate);
	
	
	function OracliszedETHUSD(
		uint _precision,
		uint _priceInUSD
	) Owned() public payable {
		
		precision = _precision;
		
		priceInUSD = _priceInUSD;
		
		UpdatePrice();
	}
	
	
	function UpdatePrice() public payable {
		
	    require(msg.sender == owner);
	    
        if (oraclize_getPrice("URL") > address(this).balance) {
			revert();
		}
		else {
			oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
		}
    }
	
	
	function __callback(bytes32 myid, string result) public {
		
		if (msg.sender != oraclize_cbAddress()) {
			revert();
		}
		
		currentETHUSD = parseInt(result, precision);
		
		priceInWei = ( 1 ether * uint256(priceInUSD) ) / uint256(currentETHUSD);
		
		lastUpdateTime = now;
		
		emit ETHUSDRateUpdate(currentETHUSD);
	}
	
}



