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


interface IPrometheusToken {
	function decimals() external view returns(uint8);
	function balanceOf(address) external view returns(uint256);
	function preICOContract() external view returns(address);
	function ICOContract() external view returns(address);
	function ForceTransfer(address _to, uint256 _value) external;
	function UnlockTokens() external;
	function BurnTokensFrom(address) external;
}

interface IPrometheusOracul {
	function unitPrice() external view returns(uint256);
	function currentETHUSD() external view returns(uint);
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
		
		require(_to != _from);
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
		require(_to != msg.sender);
		require(_value <= totalSupply);
        
		allowance[msg.sender][_to] = _value;
		
		emit Approval(msg.sender, _to, _value);
	}
	
}


contract ReturnableICO is Owned {
	IPrometheusToken public token;
	
	IPrometheusOracul public oracul;
	
	uint public priceInUSD;
	
	uint public startTime;
	
	uint public endTime;
	
	uint256 public softCap;
	
	uint256 public tokensSold;
	
	uint256 public bonusValue;
	
	uint8 public bonusPercentageOffset;
	
	mapping (address => uint256) internal spendWei;
	
	uint public returnPeriodEndTime;
	
	uint public returnPeriodDuration;
	
	event StausUpdate(string message);
	
	event TokensPurchase(address indexed buyer, uint256 ammount, uint256 bonus);
	
	
	function ReturnableICO(
		address				_owner,
		address             _token,
		address             _oracul,
		uint				_priceInUSD,
		uint256				_softCap,
		uint256				_bonusValue,
		uint8				_bonusPercentageOffset,
		uint				_returnPeriodDuration
	) Owned(_owner) public {
		token		=	IPrometheusToken(_token);
		oracul		=	IPrometheusOracul(_oracul);
		
		softCap		=	_softCap * (10 ** uint256(token.decimals()));
		
		priceInUSD	=	_priceInUSD;
		
		bonusValue	=	_bonusValue * (10 ** uint256(token.decimals()));
		
		bonusPercentageOffset = _bonusPercentageOffset;
		
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
		
		emit StausUpdate("ICO will start after delay");
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
			
			emit StausUpdate("ICO has been ended with success. Soft cap was reached.");
		}
		else {
			returnPeriodEndTime = now + returnPeriodDuration;
			
			emit StausUpdate("ICO has been ended with failure. Soft cap was not reached. Tokens can be returned.");
		}
	}
	
	
	function returnTokens() public {
		require(returnPeriodEndTime > now);
		
		require(spendWei[msg.sender] > 0);
		
		msg.sender.transfer(spendWei[msg.sender]);
		
		spendWei[msg.sender] = 0;
		
		token.BurnTokensFrom(msg.sender);
	}
	
	
	function _bonus(uint256 _value) internal view returns(uint256) {
		uint256 bonus_modif = _value / bonusValue;
		
		if (bonus_modif > 1) {
			if (bonus_modif >= 10) {
				return (_value * (10 + bonusPercentageOffset)) / 100;
			}
			else if (bonus_modif > 5) {
				return (_value * (5 + bonusPercentageOffset)) / 100;
			}
			else {
				return (_value * (bonus_modif + bonusPercentageOffset - 1)) / 100;
			}
		}
		else {
			return 0;
		}
	}
	
	
	function _tokensToBuy(uint256 _value) internal view returns(uint256) {
		return (_value * (10 ** uint256(token.decimals()))) / (priceInUSD * oracul.unitPrice());
	}
	
	
	function tokensForFinney(uint256 _finney) public view returns(uint256) {
		uint256 ammount = _tokensToBuy(_finney * 1 finney);
		
		uint256 bonus = _bonus(ammount);
		
		return (ammount + bonus);
	}
	
	
	function _buy(
		address _buyer,
		uint256 _value
	) internal returns(uint256) {
		require( (now > startTime) && (now < endTime));
		
		uint256 contract_balance = token.balanceOf(address(this));
		
		require(contract_balance > 0);
		
		uint256 ammount = _tokensToBuy(_value);
		
		require(ammount > 0);
		
		uint256 bonus = 0;
		uint256 spend_wei = _value;
		
		if (ammount > contract_balance) {
			uint256 diff = ((ammount - contract_balance) * priceInUSD * oracul.unitPrice()) / (10 ** uint256(token.decimals()));
			
			require(diff < _value);
			
			spend_wei = spend_wei - diff;
			
			ammount = contract_balance;
			
			_buyer.transfer(diff);
		}
		else {
			bonus = _bonus(ammount);
			
			if (ammount + bonus > contract_balance) {
				bonus = bonus - (contract_balance - (ammount + bonus));
			}
		}
		
		token.ForceTransfer(_buyer, ammount + bonus);
		
		spendWei[_buyer] = spendWei[_buyer] + spend_wei;
		tokensSold = tokensSold + ammount;
		
		emit TokensPurchase(_buyer, ammount, bonus);
		
		return ammount;
	}
	
	
	function () public payable {
		_buy(msg.sender, msg.value);
	}
	
	
	function buy() public payable returns(uint256) {
		uint256 ammount = _buy(msg.sender, msg.value);
		
		return ammount;
	}
	
	
	function buyFor(address _recipient) public payable {
		_buy(_recipient, msg.value);
	}
	
}

