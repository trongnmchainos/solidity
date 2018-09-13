pragma solidity ^0.4.18;
import "./Forwarder.sol";
import "./ERC20Interface.sol";
/**
 *
 * WalletSimple
 * ============
 *
 * Basic multi-signer wallet designed for use in a co-signing environment where 2 signatures are required to move funds.

 //Ví đa dấu cơ bản được thiết kế để sử dụng trong môi trường đồng ký, trong đó có 2 chữ ký được yêu cầu để chuyển tiền.
 
 * Typically used in a 2-of-3 signing configuration. Uses ecrecover to allow for 2 signatures in a single transaction.
 //Thường được sử dụng trong cấu hình ký 2/3. Sử dụng ecrecover để cho phép 2 chữ ký trong một giao dịch duy nhất.
 *
 * The first signature is created on the operation hash (see Data Formats) and passed to sendMultiSig/sendMultiSigToken
// Chữ ký đầu tiên được tạo trên băm hoạt động (xem Định dạng dữ liệu) và được truyền đến để gửiMultiSig / sendMultiSigToken
 * The signer is determined by verifyMultiSig().
 //Người ký được xác định bằng verifyMultiSig ().
 *
 * The second signature is created by the submitter of the transaction and determined by msg.signer.
//Chữ ký thứ hai được tạo bởi người gửi giao dịch và được xác định bởi msg.signer.
 *
 * Data Formats
 * ============
 *
 * The signature is created with ethereumjs-util.ecsign(operationHash).
 //Chữ ký được tạo ra với ethereumjs-util.ecsign (operationHash).
 * Like the eth_sign RPC call, it packs the values as a 65-byte array of [r, s, v].
 //Giống như cuộc gọi RPC eth_sign, nó gói các giá trị như một mảng 65 byte của [r, s, v].

 * Unlike eth_sign, the message is not prefixed.
// Không giống như eth_sign, thông báo không được thêm tiền tố.
 *
 * The operationHash the result of keccak256(prefix, toAddress, value, data, expireTime).
 //Các hoạt độngHash kết quả của keccak256 (tiền tố, toAddress, giá trị, dữ liệu, expireTime).
 * For ether transactions, `prefix` is "ETHER".
 //Đối với các giao dịch ête, `tiền tố` là" ETHER ".
 * For token transaction, `prefix` is "ERC20" and `data` is the tokenContractAddress.
// Đối với giao dịch mã thông báo, `tiền tố` là" ERC20 "và` dữ liệu` là tokenContractAddress.
 *
 *
 */
contract WalletSimple {
  // Events
  event Deposited(address from, uint value, bytes data);
  event SafeModeActivated(address msgSender);
  event Transacted(
    address msgSender, // Address of the sender of the message initiating the transaction
    //Địa chỉ của người gửi tin nhắn bắt đầu giao dịch
    address otherSigner, // Address of the signer (second signature) used to initiate the transaction
//    Địa chỉ của người ký (chữ ký thứ hai) được sử dụng để bắt đầu giao dịch
    bytes32 operation, // Operation hash (see Data Formats)
    //Băm hoạt động (xem Định dạng dữ liệu)

    address toAddress, // The address the transaction was sent to
   //Địa chỉ giao dịch đã được gửi tới

    uint value, // Amount of Wei sent to the address
    //Số tiền của Wei được gửi đến địa chỉ
    bytes data // Data sent when invoking the transaction
    //Dữ liệu được gửi khi gọi giao dịch
  );

  // Public fields
  //cac truong cong khai
  address[] public signers; // The addresses that can co-sign transactions on the wallet
 //Các địa chỉ có thể đồng ký giao dịch trên ví

  bool public safeMode = false; // When active, wallet may only send to signer addresses
//Khi hoạt động, ví chỉ có thể gửi đến địa chỉ người ký

  // Internal fields
  //Các trường nội bộ
  uint constant SEQUENCE_ID_WINDOW_SIZE = 10;
  uint[10] recentSequenceIds;

  /**
   * Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
   //Thiết lập ví đa sig đơn giản bằng cách chỉ định người ký được phép sử dụng trên ví này.
   * 2 signers will be required to send a transaction from this wallet.
   //2 người ký sẽ được yêu cầu gửi một giao dịch từ ví này.
   * Note: The sender is NOT automatically added to the list of signers.
   //Lưu ý: Người gửi KHÔNG được tự động thêm vào danh sách người ký.
   * Signers CANNOT be changed once they are set
   //Người ký không thể thay đổi sau khi được đặt
   *
   * @param allowedSigners An array of signers on the wallet
   //allowedSigners Một mảng người ký trên ví

   */
  function WalletSimple(address[] allowedSigners) public {
    if (allowedSigners.length != 3) {
      // Invalid number of signers
      //// Số lượng người ký không hợp lệ

      revert();
    }
    signers = allowedSigners;
  }

  /**
   * Determine if an address is a signer on this wallet
   //Xác định xem địa chỉ có phải là người ký trên ví này không
   * @param signer address to check
   //địa chỉ người ký để kiểm tra

   * returns boolean indicating whether address is signer or not
   //trả về boolean cho biết địa chỉ là người ký hay không
   */
  function isSigner(address signer) public view returns (bool) {
    // Iterate through all signers on the wallet and
    // Lặp lại tất cả các người ký trên ví và

    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == signer) {
        return true;
      }
    }
    return false;
  }

  /**
   * Modifier that will execute internal code block only if the sender is an authorized signer on this wallet
   */
   //Công cụ sửa đổi sẽ thực thi chặn mã nội bộ chỉ khi người gửi là người ký được ủy quyền trên ví tiền này

  modifier onlySigner {
    if (!isSigner(msg.sender)) {
      revert();
    }
    _;
  }

  /**
   * Gets called when a transaction is received without calling a method
   //Được gọi khi nhận được một giao dịch mà không cần gọi phương thức
   */
  function() public payable {
    if (msg.value > 0) {
      // Fire deposited event if we are receiving funds
      // Sự kiện gửi tiền nếu chúng tôi nhận tiền

      Deposited(msg.sender, msg.value, msg.data);
    }
  }

  /**
   * Create a new contract (and also address) that forwards funds to this contract
  // Tạo hợp đồng mới (và cả địa chỉ) chuyển tiền vào hợp đồng này

   * returns address of newly created forwarder address
   //trả về địa chỉ của địa chỉ giao nhận mới được tạo
   */
  function createForwarder() public returns (address) {
    return new Forwarder();
  }

  /**
   * Execute a multi-signature transaction from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
   //Thực hiện giao dịch đa chữ ký từ ví này bằng cách sử dụng 2 người ký: một từ msg.sender và một từ ecrecover.
   * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
   //ID chuỗi là số bắt đầu từ 1. Chúng được sử dụng để ngăn chặn các cuộc tấn công phát lại và có thể không được lặp lại.

   *
   * @param toAddress the destination address to send an outgoing transaction
   //toAddress địa chỉ đích để gửi một giao dịch gửi đi

   * @param value the amount in Wei to be sent
   //giá trị số tiền trong Wei được gửi

   * @param data the data to send to the toAddress when invoking the transaction
   //dữ liệu để gửi đến toAddress khi gọi giao dịch

   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   //expireTime số giây kể từ năm 1970 mà giao dịch này hợp lệ

   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   //id chuỗi duy nhất có thể lấy từ getNextSequenceId
   * @param signature see Data Formats
   //xem Định dạng dữ liệu
   */
  function sendMultiSig(
      address toAddress,
      uint value,
      bytes data,
      uint expireTime,
      uint sequenceId,
      bytes32 operationHash,
      bytes signature
  ) public payable onlySigner {
    // Verify the other signer
    //Xác minh người ký khác
    
    var otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);

    // Success, send the transaction
    if (!(toAddress.call.value(value)(data))) {
      // Failed executing transaction
      //Giao dịch thực thi không thành công

      revert();
    }
    Transacted(msg.sender, otherSigner, operationHash, toAddress, value, data);
  }
  
  /**
   * Execute a multi-signature token transfer from this wallet using 2 signers: one from msg.sender and the other from ecrecover.
   
   * Sequence IDs are numbers starting from 1. They are used to prevent replay attacks and may not be repeated.
   *
   * @param toAddress the destination address to send an outgoing transaction
   * @param value the amount in tokens to be sent
   * @param tokenContractAddress the address of the erc20 token contract
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   * @param signature see Data Formats
   */
  function sendMultiSigToken(
      address toAddress,
      uint value,
      address tokenContractAddress,
      uint expireTime,
      uint sequenceId,
      bytes signature
  ) public onlySigner {
    // Verify the other signer
    var operationHash = keccak256("ERC20", toAddress, value, tokenContractAddress, expireTime, sequenceId);
    
    verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);
    
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    if (!instance.transfer(toAddress, value)) {
        revert();
    }
  }
  
  /**
   * Execute a token flush from one of the forwarder addresses. This transfer needs only a single signature and can be done by any signer
   //Thực thi mã thông báo từ một trong các địa chỉ giao nhận. Việc chuyển này chỉ cần một chữ ký duy nhất và có thể được thực hiện bởi bất kỳ người ký nào
   *
   * @param forwarderAddress the address of the forwarder address to flush the tokens from
   //forwarderThêm địa chỉ của địa chỉ giao nhận để xóa các thẻ từ
   * @param tokenContractAddress the address of the erc20 token contract
   //tokenContractThêm địa chỉ của hợp đồng token erc20
   */
  function flushForwarderTokens(
    address forwarderAddress, 
    address tokenContractAddress
  ) public onlySigner {
    Forwarder forwarder = Forwarder(forwarderAddress);
    forwarder.flushTokens(tokenContractAddress);
  }

  /**
   * Do common multisig verification for both eth sends and erc20token transfers
   //Thực hiện xác minh đa nhân phổ biến cho cả eth gửi và chuyển giao erc20token
   *
   * @param toAddress the destination address to send an outgoing transaction
   * @param operationHash see Data Formats
   //operationHash xem Định dạng dữ liệu

   * @param signature see Data Formats
   //* @param signature xem Định dạng Dữ liệu

   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   //* @param expireTime số giây kể từ năm 1970 mà giao dịch này hợp lệ

   * @param sequenceId the unique sequence id obtainable from getNextSequenceId
   //* @param sequenceId id trình tự duy nhất có thể lấy từ getNextSequenceId

   * returns address that has created the signature
   //* trả về địa chỉ đã tạo chữ ký

   */
  function verifyMultiSig(
      address toAddress,
      bytes32 operationHash,
      bytes signature,
      uint expireTime,
      uint sequenceId
  ) private returns (address) {

    var otherSigner = recoverAddressFromSignature(operationHash, signature);

    // Verify if we are in safe mode. In safe mode, the wallet can only send to signers
    //// Xác minh xem chúng tôi có ở chế độ an toàn không. Ở chế độ an toàn, ví chỉ có thể gửi cho người ký
    if (safeMode && !isSigner(toAddress)) {
      // We are in safe mode and the toAddress is not a signer. Disallow!
      //// Chúng tôi đang ở trong chế độ an toàn và toAddress không phải là người ký tên. Không cho phép!
      revert();
    }
    // Verify that the transaction has not expired
    //// Xác minh rằng giao dịch chưa hết hạn
    //
    if (expireTime < block.timestamp) {
      // Transaction expired
      // Giao dịch đã hết hạn

      revert();
    }

    // Try to insert the sequence ID. Will revert if the sequence id was invalid
    //// Thử chèn ID trình tự. Sẽ hoàn nguyên nếu id trình tự không hợp lệ
    tryInsertSequenceId(sequenceId);

    if (!isSigner(otherSigner)) {
      // Other signer not on this wallet or operation does not match arguments
      //// Người ký khác không phải trên ví hoặc hoạt động này không khớp với đối số
      revert();
    }
    if (otherSigner == msg.sender) {
      // Cannot approve own transaction
      //// Không thể phê duyệt giao dịch của riêng

      revert();
    }

    return otherSigner;
  }

  /**
   * Irrevocably puts contract into safe mode. When in this mode, transactions may only be sent to signing addresses.
   //* Không thể hủy bỏ hợp đồng vào chế độ an toàn. Khi ở chế độ này, các giao dịch chỉ có thể được gửi đến các địa chỉ ký.
   */
  function activateSafeMode() public onlySigner {
    safeMode = true;
    SafeModeActivated(msg.sender);
  }

  /**
   * Gets signer's address using ecrecover
   //Nhận địa chỉ của người ký sử dụng ecrecover
   * @param operationHash see Data Formats
   //* @param operationHash xem Định dạng Dữ liệu
   * @param signature see Data Formats
   * @param signature xem Định dạng Dữ liệu

   * returns address recovered from the signature
   * trả về địa chỉ được thu hồi từ chữ ký

   */
  function recoverAddressFromSignature(
    bytes32 operationHash,
    bytes signature
  ) private pure returns (address) {
    if (signature.length != 65) {
      revert();
    }
    // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
    //// Chúng ta cần giải nén chữ ký, được cho dưới dạng một mảng gồm 65 byte (như eth.sign)

    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := and(mload(add(signature, 65)), 255)
    }
    if (v < 27) {
      v += 27; // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
    }
    return ecrecover(operationHash, v, r, s);
  }

  /**
   * Verify that the sequence id has not been used before and inserts it. Throws if the sequence ID was not accepted.
   //* Xác minh rằng id trình tự chưa được sử dụng trước đó và chèn nó vào. Ném nếu ID chuỗi không được chấp nhận.

   * We collect a window of up to 10 recent sequence ids, and allow any sequence id that is not in the window and
   //* Chúng tôi thu thập một cửa sổ lên đến 10 id chuỗi gần đây và cho phép bất kỳ id trình tự nào không có trong cửa sổ và

   * greater than the minimum element in the window.
   * lớn hơn phần tử tối thiểu trong cửa sổ.

   * @param sequenceId to insert into array of stored ids
   //* @param sequenceId để chèn vào mảng các id được lưu trữ

   */
  function tryInsertSequenceId(uint sequenceId) private onlySigner {
    // Keep a pointer to the lowest value element in the window
    //// Giữ con trỏ đến phần tử giá trị thấp nhất trong cửa sổ

    uint lowestValueIndex = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] == sequenceId) {
        // This sequence ID has been used before. Disallow!
        //// ID chuỗi này đã được sử dụng trước đó. Không cho phép!

        revert();
      }
      if (recentSequenceIds[i] < recentSequenceIds[lowestValueIndex]) {
        lowestValueIndex = i;
      }
    }
    if (sequenceId < recentSequenceIds[lowestValueIndex]) {
      // The sequence ID being used is lower than the lowest value in the window
     //// ID trình tự được sử dụng thấp hơn giá trị thấp nhất trong cửa sổ

      // so we cannot accept it as it may have been used before
      //// vì vậy chúng tôi không thể chấp nhận nó vì nó có thể đã được sử dụng trước đó

      revert();
    }
    if (sequenceId > (recentSequenceIds[lowestValueIndex] + 10000)) {
      // Block sequence IDs which are much higher than the lowest value
      //// Chặn ID chuỗi cao hơn nhiều so với giá trị thấp nhất

      // This prevents people blocking the contract by using very large sequence IDs quickly
      //// Điều này ngăn chặn mọi người chặn hợp đồng bằng cách sử dụng ID chuỗi rất lớn nhanh chóng

      revert();
    }
    recentSequenceIds[lowestValueIndex] = sequenceId;
  }

  /**
   * Gets the next available sequence ID for signing when using executeAndConfirm
   //* Nhận ID chuỗi khả dụng tiếp theo để ký khi sử dụng executeAndConfirm
   * returns the sequenceId one higher than the highest currently stored
  //* trả về dãy thứ tự cao hơn giá trị cao nhất hiện được lưu trữ
  */
  function getNextSequenceId() public view returns (uint) {
    uint highestSequenceId = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] > highestSequenceId) {
        highestSequenceId = recentSequenceIds[i];
      }
    }
    return highestSequenceId + 1;
  }
}