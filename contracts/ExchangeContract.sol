// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "./iface/IERC721.sol";
import "./iface/IFeeContract.sol";
import "./lib/SafeMath.sol";
import "./lib/AddressPayable.sol";

contract ExchangeContract {
	using SafeMath for uint256;
	using address_make_payable for address;

	// 手续费2%
	uint256 feeRate = 2;
	// 手续费合约
	IFeeContract feeCon = IFeeContract(0x0);
	// 商品
	struct Goods {
		address owner;
		address tokenAddress;
		uint256 tokenId;
		uint256 ethAmount;
		bool flag;
		string info;
	}
	// 商品列表
	Goods[] GoodsList;

	event Add(uint256 index, address owner, address tokenAddress, uint256 tokenId, uint256 ethAmount);

	constructor() public {}

	//---------modifier---------

    modifier onContract() {
        require(msg.sender == tx.origin, "Log:ExchangeContract:onContract");
        _;
    }

	/// @dev 增加商品
    /// @param _tokenAddress ERC721地址
    /// @param _tokenId ERC721 ID
    /// @param _ethAmount 商品价格
    /// @param data 描述
	function addGoods(address _tokenAddress, 
		              uint256 _tokenId, 
		              uint256 _ethAmount,
		              string memory data) public onContract {
		IERC721(_tokenAddress).safeTransferFrom(address(tx.origin), address(this), _tokenId);
		GoodsList.push(Goods(address(msg.sender), _tokenAddress, _tokenId, _ethAmount, true, data));

		emit Add(GoodsList.length.sub(1), address(tx.origin), _tokenAddress, _tokenId, _ethAmount);
	}

	/// @dev 修改商品
    /// @param index 订单编号
    /// @param _ethAmount 商品价格
    /// @param data 描述
	function changeGoods(uint256 index, 
		                 uint256 ethAmount, 
		                 string memory data) public onContract {
		Goods storage myGoods = GoodsList[index];
		require(myGoods.flag, "Log:ExchangeContract:flag");
		if (ethAmount != 0){
			myGoods.ethAmount = ethAmount;
		}
		if (bytes(data).length != 0) {
			myGoods.info = data;
		}
	}

	/// @dev 购买商品
    /// @param index 订单编号
	function buyGoods(uint256 index) public payable onContract {
		Goods storage myGoods = GoodsList[index];
		require(myGoods.flag, "Log:ExchangeContract:flag");
		uint256 fee = myGoods.ethAmount.mul(feeRate).div(100);
		require(msg.value == myGoods.ethAmount.add(fee), "Log:ExchangeContract:!value");
		IERC721(myGoods.tokenAddress).safeTransferFrom(address(this), address(tx.origin), myGoods.tokenId);
		myGoods.flag = false;
		payEth(address(myGoods.owner), myGoods.ethAmount);
		feeCon.addFee{ value:fee }();
	}

	/// @dev 下架商品
    /// @param index 订单编号
	function subGoods(uint256 index) public onContract {
		Goods storage myGoods = GoodsList[index];
		require(address(tx.origin) == myGoods.owner, "Log:ExchangeContract:!owner");
		require(myGoods.flag, "Log:ExchangeContract:flag");
		IERC721(myGoods.tokenAddress).safeTransferFrom(address(this), address(tx.origin), myGoods.tokenId);
		myGoods.flag = false;
	}

	function onERC721Received(address operator, 
				              address from, 
				              uint256 tokenId, 
				              bytes calldata data) public returns (bytes4){
		return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
	}

	function payEth(address account, uint256 asset) private {
        address payable add = account.make_payable();
        add.transfer(asset);
    }

}