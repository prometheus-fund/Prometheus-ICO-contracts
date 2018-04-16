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

contract PrometheusToken {
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
	
	address public preICOContract;
	
	address public ICOContract;
	
	address internal owner;
	
	bool internal isLocked;
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	
	event Approval(address indexed from, address indexed to, uint256 value);
	
	event TokenUnlocked(string message);
	
	
	
	function PrometheusToken(
		string _name,
		string _symbol,
		uint8 _decimals,
	) public {
		
		isLocked = true;
		
		name		=	_name;
		symbol		=	_symbol;
		decimals	=	_decimals;
		
		owner		=	msg.sender;
	}
	
	
	//
	function transfer(address _to, uint256 _value) public {
		
		require(!isLocked);
		
        _transfer(msg.sender, _to, _value);
    }
	
	
	//
	function transferFrom(address _from, address _to, uint256 _value) public {
		
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
	function approve(address _to, uint256 _value) public {
		
		require(!isLocked)
		
        require(_to != 0x0);
		
		require(_value <= totalSupply);
        
		allowance[msg.sender][_to] = _value;
		
		emit Approval(msg.sender, _to, _value);
	}
	
	
	//
	function _transfer(address _from, address _to, uint256 _value) internal {
        
        require(_to != 0x0);
        
        require(_value > 0);
        
        require(balanceOf[_from] >= _value);
        
        balanceOf[_from] -= _value;
		
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
    }
	
	
	function __setPreICOandICO(
		address _preICOContract,
		uint256 _preICOEmmision,
		address _ICOContract,
		uint256 _ICOEmmision,
	) public {
		
		require(msg.sender == owner);
		
		require( (preICOContract == 0x0) && (ICOContract == 0x0) );
		
		preICOContract = _preICOContract;
		
		balanceOf[preICOContract] = _preICOEmmision * ( 10 ** uint256(decimals) );
		
		ICOContract = _ICOContract;
		
		balanceOf[ICOContract] = _ICOEmmision * ( 10 ** uint256(decimals) );
		
		totalSupply = balanceOf[ICOContract] + balanceOf[preICOContract];
	}
	
	
	
	function __forceTransfer(address _to, uint256 _value) public {
		
		require( (msg.sender == preICOContract) || (msg.sender == ICOContract) );
		
        _transfer(allowedContract, _to, _value);
	}
	
	
	function __unlockTokens() public {
		require(msg.sender == ICOContract);
		
		isLocked = false;
		
		emit TokenUnlocked("Tokens have been unlocked. Transfer and approve functions are now available.");
	}
	
}