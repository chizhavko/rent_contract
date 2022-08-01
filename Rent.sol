// SPDX-License-Identifier: MIT
pragma solidity 0.8.15; /// ^ means current version or above. Also >= 0.8.8 < 0.9.0 works to make a range of versions 


/*
 ⁃ Practice: Implement the following smart contract: 
 Хозяин квартиры в Минске хочет сдавать ее и получать месячную плату в $300.
 Если кто-то хочет заселиться, он соглашается на условия и начинает аренду сроком 1 год, при этом квартиру больше никто не может арендовать (до истечения текущей аренды). 
 Ежемесячно 25го числа сумма аренды за следующий месяц проживания переводится арендодателю от нанимателя. 
 Если денег нет в срок, происходит расторжение договора и выселение. 
 Если арендодатель выселяет нанимателя раньше срока, то первый выплачивает последнему компенсацию в $1000.
*/
contract Deposite {

    struct FlatInfo {
        uint256 deposite;
        uint256 price;
        address payable landlord;
        bool isAvailable;
    }

    struct PayableInfo {
        address payable tenant;
        uint256 paidAmount;
        uint256 signDate;
        uint256 deadline;
        uint256 duration;
    }

    FlatInfo private _flatInfo;
    PayableInfo private _payInfo;

    event Sign(uint256 duration, address sender);
    event Paid(FlatInfo flatInfo, PayableInfo payableInfo);
    event DeclinedBecauseOfTenant();
    event DeclinedBecauseOfLandlord(uint256 date, PayableInfo info);


    constructor(uint256 deposite, uint256 price) payable {
        require(msg.value >= deposite);
        _flatInfo = FlatInfo(deposite, price, payable(msg.sender), true);
    }

    function sign(uint256 duration) public payable {
        require(msg.sender != _flatInfo.landlord, "Landlord cannot sign own offer");
        require(msg.value >= _flatInfo.price, "Sender not has enough money");
        require(_flatInfo.isAvailable, "Flat is not available");
        require(duration > 1 && duration <= 12, "Duration should be more than month and no longer than one year");

        _flatInfo.isAvailable = false;
        _flatInfo.landlord.transfer(_flatInfo.price);

        uint256 deadline = block.timestamp + 30 * 1 days;
        _payInfo = PayableInfo(payable(msg.sender), _flatInfo.price, block.timestamp, deadline, duration);

        emit Sign(duration, msg.sender);
    }

    function pay(uint256 amount) public payable {
        require(msg.sender != _flatInfo.landlord, "Landlord cannot sign own offer");
        require(msg.value >= amount, "Sender not has enough money");
        require(_flatInfo.isAvailable, "Flat is not available");
        require(amount == _flatInfo.price, "Wrong amount passed");
        require(_payInfo.paidAmount + 1 <= _payInfo.duration, "Extra pay, you are good");

        _flatInfo.landlord.transfer(amount);
        _payInfo.paidAmount += 1;
        _payInfo.deadline += 30 * 1 days;

        emit Paid(_flatInfo, _payInfo);
    }

    function isTenantPaidForFlat() public view returns(bool) {
        return block.timestamp <= _payInfo.deadline;
    }

    function declinedBecauseOfTenant() public {
        emit DeclinedBecauseOfTenant();

        _flatInfo = FlatInfo(_flatInfo.deposite, _flatInfo.price, _flatInfo.landlord, true);
        _payInfo = PayableInfo(payable(address(0)),0,0,0,0);
    }

    function declinedBecauseOfLandlord() public payable {
        require(_payInfo.paidAmount < _payInfo.duration);

        emit DeclinedBecauseOfLandlord(block.timestamp, _payInfo);

        _payInfo.tenant.transfer(_flatInfo.deposite);
        _flatInfo = FlatInfo(_flatInfo.deposite, _flatInfo.price, _flatInfo.landlord, true);
        _payInfo = PayableInfo(payable(address(0)),0,0,0,0);
    }
}