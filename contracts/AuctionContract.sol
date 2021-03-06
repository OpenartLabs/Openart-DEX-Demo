// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "./iface/IERC721.sol";
import "./iface/IFeeContract.sol";
import "./lib/SafeMath.sol";
import "./lib/AddressPayable.sol";

contract AuctionContract {
	using SafeMath for uint256;
	using address_make_payable for address;

	// 手续费合约
	IFeeContract feeCon = IFeeContract(0x0);

	struct Auction {
		address owner;					// 拥有者
		address tokenAddress;			// 721 地址
		uint256 tokenId;				// 721 tokenid
		uint256 aucAmount;              // 竞拍价
		uint256 amountSpan;             // 最小竞价单位
		uint256 startTime;              // 开始时间
		uint256 endTime;                // 结束时间
		uint256 incentive;              // 激励比例
		bool flag;                      // 0关闭 1运行中
		string info;                    // 介绍
		address aucAddress;				// 当前拍卖地址
		uint256 leftAmount;				// 剩余ETH
	}
	Auction[] auctionList;

	constructor() public {}

	//---------modifier---------

    modifier noContract() {
        require(msg.sender == tx.origin, "Log:AuctionContract:onContract");
        _;
    }

	/// @dev 增加拍卖
    /// @param tokenAddress ERC721地址
    /// @param tokenId ERC721 ID
    /// @param time 拍卖持续时间
    /// @param startAmount 起拍价
    /// @param amountSpan 拍卖最小价格差
    /// @param incentive 激励比例
    /// @param data 描述
	function addAuction(address tokenAddress, 
		                uint256 tokenId, 
		                uint256 time, 
		                uint256 startAmount,
		                uint256 amountSpan, 
		                uint256 incentive, 
		                string memory data) public noContract{
		require(tokenAddress != address(0x0));
		require(time >= 1 days);
		require(startAmount >= 0);
		require(amountSpan > 0);
		require(incentive <= 20 && incentive >= 0);
		IERC721(tokenAddress).safeTransferFrom(address(tx.origin), address(this), tokenId);
		auctionList.push(Auction(address(tx.origin), tokenAddress, tokenId, startAmount, amountSpan, now, uint256(now).add(time), incentive, true, data, address(0x0), 0));
	}

	/// @dev 竞拍
    /// @param index 拍卖单编号
    /// @param amount 出价
	function continueBidding(uint256 index, uint256 amount) public payable noContract {
		Auction storage myAuction = auctionList[index];
		require(now <= myAuction.endTime, "Log:AuctionContract:endTime");
		require(myAuction.flag, "Log:AuctionContract:flag");
		require(msg.value == amount);
		require(amount >= myAuction.aucAmount);
		if (myAuction.aucAddress == address(0x0)) {
			myAuction.aucAddress = address(tx.origin);
			myAuction.aucAmount = amount;
			myAuction.leftAmount = amount;
		} else {
			address frontOwner = myAuction.aucAddress;
			uint256 frontAmount = myAuction.aucAmount;
			uint256 incAmount = 0;
			if (myAuction.incentive != 0) {
				incAmount = amount.sub(myAuction.aucAmount).mul(myAuction.incentive).div(100);
			}
			myAuction.aucAddress = address(tx.origin);
			myAuction.leftAmount = amount.sub(incAmount);
			myAuction.aucAmount = amount;
			payEth(frontOwner, frontAmount.add(incAmount));
		}
	}

	/// @dev 竞拍成功，交易
    /// @param index 拍卖单编号
	function auctionSuccess(uint256 index) public noContract {
		Auction storage myAuction = auctionList[index];
		require(now > myAuction.endTime, "Log:AuctionContract:endTime");
		require(myAuction.flag, "Log:AuctionContract:flag");
		require(myAuction.aucAddress != address(0x0), "Log:AuctionContract:noAuc");
		myAuction.flag = false;

		IERC721(myAuction.tokenAddress).safeTransferFrom(address(this), address(myAuction.aucAddress), myAuction.tokenId);

		uint256 fee = myAuction.aucAmount.mul(5).div(100);
		feeCon.addFee{ value:fee }();
		payEth(myAuction.owner, myAuction.leftAmount.sub(fee));

	}

	/// @dev 修改竞拍信息
	/// @param index 拍卖单编号
    /// @param time 拍卖持续时间
    /// @param startAmount 起拍价
    /// @param amountSpan 拍卖最小价格差
    /// @param incentive 激励比例
    /// @param data 描述
	function modifyInformation(uint256 index,
		                       uint256 time, 
		                	   uint256 startAmount,
		                       uint256 amountSpan, 
		                       uint256 incentive, 
		                       string memory data) public noContract {
		Auction storage myAuction = auctionList[index];
		require(myAuction.owner == address(tx.origin), "Log:AuctionContract:!owner");
		require(myAuction.aucAddress == address(0x0), "Log:AuctionContract:noAuc");
		require(now > myAuction.endTime, "Log:AuctionContract:endTime");
		require(myAuction.flag, "Log:AuctionContract:flag");

		require(startAmount >= 0);
		require(time >= 1 days);
		require(amountSpan > 0);
		require(incentive <= 20 && incentive >= 0);
		myAuction.aucAmount = startAmount;
		myAuction.startTime = now;
		myAuction.endTime = now.add(time);
		myAuction.amountSpan = amountSpan;
		myAuction.incentive = incentive;
		myAuction.info = data;
	}

	/// @dev 下架竞拍
	/// @param index 拍卖单编号
	function subAuction(uint256 index) public noContract {
		Auction storage myAuction = auctionList[index];
		require(myAuction.owner == address(tx.origin), "Log:AuctionContract:!owner");
		require(myAuction.aucAddress == address(0x0), "Log:AuctionContract:noAuc");
		require(now > myAuction.endTime, "Log:AuctionContract:endTime");
		require(myAuction.flag, "Log:AuctionContract:flag");
		IERC721(myAuction.tokenAddress).safeTransferFrom(address(this), address(tx.origin), myAuction.tokenId);
		myAuction.flag = false;
	}

	function onERC721Received(address operator, 
				              address from, 
				              uint256 tokenId, 
				              bytes calldata data) public returns (bytes4) {
		return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
	}

	function payEth(address account, uint256 asset) private {
        address payable add = account.make_payable();
        add.transfer(asset);
    }

}