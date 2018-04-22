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

import "github.com/JustFixMe/Prometheus-ICO-contracts/Contracts/PrometheusICO.sol";


contract PrometheusToken is Owned, ERC20Token {
	
	address public preICOContract;
	
	address public ICOContract;
	
	bool internal isLocked;
	
	event TokenUnlocked(string message);
	
	
	function PrometheusToken(
		string _name,
		string _symbol,
		uint8 _decimals,
		address _preICOContract,
		uint256 _preICOEmmision,
		address _ICOContract,
		uint256 _ICOEmmision
	) Owned() ERC20Token(_name, _symbol, _decimals, (_preICOEmmision + _ICOEmmision)) public {
		isLocked		=	true;		
		preICOContract	=	_preICOContract;
		ICOContract		=	_ICOContract
		
		balanceOf[_preICOContract] = _preICOEmmision * ( 10 ** uint256(_decimals) );
		balanceOf[_ICOContract] = _ICOEmmision * ( 10 ** uint256(_decimals) );
	}
	
	
	//
	function transfer(
		address _to,
		uint256 _value
	) public {
		
		require(!isLocked);
		
        _transfer(msg.sender, _to, _value);
    }
	
	
	//
	function transferFrom(
		address _from,
		address _to,
		uint256 _value
	) public {
		
		require(!isLocked);
		
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
		
		require(!isLocked)
		
        require(_to != 0x0);
		
		require(_value <= totalSupply);
        
		allowance[msg.sender][_to] = _value;
		
		emit Approval(msg.sender, _to, _value);
	}
	
	
	//
	function ForceTransfer(
		address _to,
		uint256 _value
	) external {
		
		require( (msg.sender == preICOContract) || (msg.sender == ICOContract) );
		
        _transfer(msg.sender, _to, _value);
	}
	
	
	//
	function UnlockTokens() external {
		require(msg.sender == ICOContract);
		
		require(isLocked);
		
		isLocked = false;
		
		emit TokenUnlocked("Tokens have been unlocked. Transfer and approve functions are now available.");
	}
	
	
	function BurnTokensFrom(address _from) external {
		
		require( (msg.sender == preICOContract) || (msg.sender == ICOContract) );
		
		require(balanceOf[_from] > 0);
		
		totalSupply = totalSupply - balanceOf[_from];
		balanceOf[_from] = 0;
	}
	
}