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
	function BurnTokensFrom(address) external;
}


contract Owned {
	address internal owner;
	
	function Owned(address _owner) public {
		owner = _owner;
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
	
	
	function ERC20Token(
		string _name,
		string _symbol,
		uint8 _decimals,
		uint256 _totalSupply
	) public {		
		name			=	_name;
		symbol			=	_symbol;
		decimals		=	_decimals;
		totalSupply		=	_totalSupply * (10 ** uint256(_decimals));
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
	
	
	
	//
	function transfer(
		address _to,
		uint256 _value
	) public {
		
        _transfer(msg.sender, _to, _value);
    }
	
	
	//
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	) public {
		
        require(allowance[_from][_to] > 0);
        
        if (allowance[_from][_to] < _value) {
            uint256 to_transfer = allowance[_from][_to];
            
            allowance[_from][_to] = 0;
            
            _transfer(_from, _to, to_transfer);
        }
        else {
            allowance[_from][_to] -= _value;
            
            _transfer(_from, _to, _value);
        }
    }
	
	//
	function approve(
		address _to,
		uint256 _value
	) public {
		
        require(_to != 0x0);
		
		require(_value <= totalSupply);
        
		allowance[msg.sender][_to] = _value;
		
		emit Approval(msg.sender, _to, _value);
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
		address _owner,
		uint _precision,
		uint _priceInUSD
	) Owned(_owner) public payable {
		
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


contract ReturnableICO is OracliszedETHUSD {
	IPrometheusToken public token;
	
	uint public startTime;
	
	uint public endTime;
	
	uint256 internal softCap;
	
	uint256 internal tokensSold;
	
	mapping (address => uint256) internal spendWei;
	
	uint internal returnPeriodEndTime;
	
	uint public returnPeriodDuration;
	
	event TokenPurchase(address indexed buyer, uint256 ammount);
	
	
	function ReturnableICO(
		address				_owner,
		address             _token,
		uint				_precision,
		uint				_priceInUSD,
		uint256				_softCap,
		uint				_returnPeriodDuration
	) OracliszedETHUSD(_owner, _precision, _priceInUSD) public payable {
		token		=	IPrometheusToken(_token);
		softCap		=	_softCap * (10 ** uint256(token.decimals()));
		
		returnPeriodDuration = _returnPeriodDuration * 1 minutes;
	}
	
	//In minutes
	function StartICO(
		uint	_delay,
		uint	_duration
	) public {
		require(msg.sender == owner);
		
		require(startTime == 0);
		
		require(token.balanceOf(address(this)) > 0);
		
		startTime = now + (_delay * 1 minutes);
		
		endTime = startTime + ( _duration * 1 minutes);
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
				token.BurnTokensFrom(address(this));
			}
		}
		else {
			returnPeriodEndTime = now + returnPeriodDuration;
		}
	}
	
	
	function returnTokens() public {
		require(returnPeriodEndTime > now);
		
		require(spendWei[msg.sender] > 0);
		
		msg.sender.transfer(spendWei[msg.sender]);
		
		spendWei[msg.sender] = 0;
		
		token.BurnTokensFrom(msg.sender);
	}
	
	
	function _buy(
		address _buyer,
		uint256 _value
	) internal returns(uint256) {
		require( (now > startTime) && (now < endTime));
		
		uint256 contract_balance = token.balanceOf(address(this));
		
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
		
		spendWei[_buyer] = spendWei[_buyer] + _value;
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