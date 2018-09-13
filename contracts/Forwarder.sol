pragma solidity ^0.4.18;
import "./ERC20Interface.sol";
/**
 * Contract that will forward any incoming Ether to the creator of the contract
 //Hợp đồng sẽ chuyển tiếp mọi Ether đến cho người goi hợp đồng
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  //Địa chỉ mà bất kỳ khoản tiền nào được gửi đến hợp đồng này sẽ được chuyển tiếp
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

  /**
   * Create the contract, and sets the destination address to that of the creator
   //Tạo hợp đồng và đặt địa chỉ đích thành địa chỉ của người sáng tạo
   */
  function Forwarder() public {
    parentAddress = msg.sender;
  }

  /**
   * Modifier that will execute internal code block only if the sender is the parent address
   //Modifier sẽ chỉ thực hiện chặn mã nội bộ nếu người gửi là địa chỉ chính
   */
  modifier onlyParent {
    if (msg.sender != parentAddress) {
      revert();
    }
    _;
  }

  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the parent address
   //Hàm mặc định; Được gọi khi Ether được gửi và chuyển tiếp đến địa chỉ gốc
   */
  function() public payable {
    // throws on failure
    parentAddress.transfer(msg.value);
    // Fire off the deposited event if we can forward it
    //Kích hoạt sự kiện được gửi nếu chúng tôi có thể chuyển tiếp sự kiện
    ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

  /**
   * Execute a token transfer of the full balance from the forwarder token to the parent address
   //Thực hiện chuyển mã thông báo toàn bộ số dư từ mã thông báo giao nhận đến địa chỉ gốc
   * @param tokenContractAddress the address of the erc20 token contract
   tokenContractThêm địa chỉ của hợp đồng token erc20

   */
  function flushTokens(address tokenContractAddress) public onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    var forwarderAddress = address(this);
    var forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      revert();
    }
  }

  /**
   * It is possible that funds were sent to this address before the contract was deployed.
   Có thể là số tiền đã được gửi đến địa chỉ này trước khi hợp đồng được triển khai.
   * We can flush those funds to the parent address.
   //Chúng tôi có thể chuyển các khoản tiền đó đến địa chỉ chính.
   */
  function flush() public {
    // throws on failure
    parentAddress.transfer(this.balance);
  }
}
