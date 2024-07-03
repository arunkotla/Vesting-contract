// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VestingToken is ERC20, Ownable {

    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 start;
        uint256 duration;
        uint256 interval;
    }

    mapping(address => VestingSchedule) private _vestingSchedules;

    event TokensBurned(address indexed burner, uint256 value);
    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function createVestingSchedule(
        address beneficiary, 
        uint256 totalAmount, 
        uint256 start, 
        uint256 duration, 
        uint256 interval
    ) 
        external 
        onlyOwner 
    {
        require(totalAmount > 0, "Total amount must be greater than zero");
        require(_vestingSchedules[beneficiary].totalAmount == 0, "Vesting schedule already exists for this beneficiary");
        require(interval > 0, "Interval must be greater than zero");
        require(duration % interval == 0, "Duration must be a multiple of interval");

        _vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: totalAmount,
            releasedAmount: 0,
            start: start,
            duration: duration,
            interval: interval
        });

        _transfer(msg.sender, address(this), totalAmount);
    }

    function releaseVestedTokens() external {
        VestingSchedule storage schedule = _vestingSchedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule for this address");
        
        uint256 vestedAmount = _vestedAmount(schedule);
        uint256 releasableAmount = vestedAmount - schedule.releasedAmount;

        require(releasableAmount > 0, "No tokens to release");

        schedule.releasedAmount += releasableAmount;
        _transfer(address(this), msg.sender, releasableAmount);

        emit TokensReleased(msg.sender, releasableAmount);
    }

    function _vestedAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        if (block.timestamp < schedule.start) {
            return 0;
        } else if (block.timestamp >= schedule.start + schedule.duration) {
            return schedule.totalAmount;
        } else {
            uint256 timeElapsed = block.timestamp - schedule.start;
            uint256 totalIntervals = schedule.duration / schedule.interval;
            uint256 intervalsElapsed = timeElapsed / schedule.interval;
            uint256 vestedAmount = (schedule.totalAmount * intervalsElapsed) / totalIntervals;
            return vestedAmount;
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
}
