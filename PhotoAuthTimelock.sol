// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title PhotoAuthTimelock
/// @notice 촬영 시각과 온체인 도달 시각의 차이를 검증해, AI로 생성된 사진이
///         뒤늦게 제출되는 것을 원천 차단하는 타임락 컨트랙트.
///         실제 서비스에서는 클라이언트가 [사진 픽셀 해시 + 촬영 시점 블록 해시]를
///         결합한 combinedHash를 만들어 이 컨트랙트에 제출한다.
contract PhotoAuthTimelock {
    /// @dev 촬영-도달 시각 차이 허용 한도 (초)
    uint256 public constant MAX_DELAY_SECONDS = 2;

    struct PhotoRecord {
        uint256 captureTimestamp;   // 클라이언트가 보고한 촬영 시각 (unix seconds)
        uint256 verifiedAt;         // 트랜잭션이 체인에 도달한 시각
        address submitter;
        bool timelockPassed;        // ②단계: 시간적 진위성 검증 결과
        bool aiScreenCheckPassed;   // ③단계: AI 재촬영 탐지 결과 (오프체인 계산 → 온체인 기록)
        bool finalApproved;         // 최종 인증 여부 (①②③ 모두 통과)
    }

    mapping(bytes32 => PhotoRecord) public records;

    event PhotoVerified(
        bytes32 indexed combinedHash,
        address indexed submitter,
        bool timelockPassed,
        bool aiScreenCheckPassed,
        bool finalApproved
    );

    /// @param combinedHash keccak256(사진 픽셀 해시, 촬영 시점 블록 해시) — ①단계 결과물
    /// @param captureTimestamp 클라이언트 촬영 시각 (unix seconds)
    /// @param aiScreenCheckPassed 오프체인 AI 재촬영 탐지 결과
    ///
    /// ⚠ 데모 단순화 지점: 프로덕션에서는 aiScreenCheckPassed 값을 아무나 조작해
    /// true로 제출할 수 없도록, 신뢰된 오라클 서명 검증(예: AI 서버의 서명을
    /// ecrecover로 확인)이 추가로 필요하다. 이번 해커톤 프로토타입에서는
    /// 파이프라인의 구조를 보여주는 데 집중해 이 부분은 파라미터로 단순화했다.
    function submitPhotoProof(
        bytes32 combinedHash,
        uint256 captureTimestamp,
        bool aiScreenCheckPassed
    ) external {
        require(records[combinedHash].submitter == address(0), "Already submitted");

        uint256 arrivalTimestamp = block.timestamp;
        bool timelockPassed;
        if (arrivalTimestamp >= captureTimestamp) {
            timelockPassed = (arrivalTimestamp - captureTimestamp) <= MAX_DELAY_SECONDS;
        } else {
            // captureTimestamp가 미래 시각이면(시계 위조 시도) 무조건 거부
            timelockPassed = false;
        }

        bool approved = timelockPassed && aiScreenCheckPassed;

        records[combinedHash] = PhotoRecord({
            captureTimestamp: captureTimestamp,
            verifiedAt: arrivalTimestamp,
            submitter: msg.sender,
            timelockPassed: timelockPassed,
            aiScreenCheckPassed: aiScreenCheckPassed,
            finalApproved: approved
        });

        emit PhotoVerified(combinedHash, msg.sender, timelockPassed, aiScreenCheckPassed, approved);
    }

    function isVerified(bytes32 combinedHash) external view returns (bool) {
        return records[combinedHash].finalApproved;
    }
}
