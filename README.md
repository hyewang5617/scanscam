# 온체인 타임락 + AI 재촬영 탐지 — 사진 진위 인증 데모

BLOCK AI✳26 해커톤 프로젝트 기획제안서에 대응하는 작동 프로토타입입니다.

## 구성

```
demo/
├── index.html                     # 실행 데모 (브라우저에서 바로 열면 됨)
├── contracts/
│   └── PhotoAuthTimelock.sol      # 타임락 검증 스마트컨트랙트
└── README.md
```

## 데모 실행 방법

`index.html`을 브라우저로 그냥 열면 됩니다. 별도 설치나 서버가 필요 없어요.

1. **카메라로 테스트**: "카메라 켜기" → "촬영 & 인증 시작". 카메라 권한을 허용해야 합니다.
2. **카메라 없이 테스트**: "샘플: 실물 촬영" / "샘플: 화면 재촬영(부정 시도)" 버튼으로 두 가지 결과를 바로 확인할 수 있어요.
3. **타임락 실패 재현**: "지연 공격 시뮬레이션" 체크박스를 켜면 3초 지연 후 제출되어 ②단계에서 거부되는 걸 볼 수 있어요.

## 기획서 아키텍처와의 대응 관계

| 기획서 단계 | 데모 구현 |
|---|---|
| ① 실시간 온체인 난수 주입 | Sepolia 테스트넷 공개 RPC(`ethereum-sepolia-rpc.publicnode.com`)에 실시간 접속해 최신 블록 해시를 가져옵니다. 네트워크가 막히면 화면에 "시뮬레이션 모드"로 표시하고 암호학적 난수로 대체합니다. |
| ② 스마트컨트랙트 타임락 | `contracts/PhotoAuthTimelock.sol`에 실제 Solidity 코드로 구현. 데모 화면에서는 동일한 로직(2초 초과 시 거부)을 브라우저에서 재현해 즉시 결과를 보여줍니다. |
| ③ AI 재촬영 탐지 | 학습된 딥러닝 모델 대신, FFT(고속푸리에변환) 기반 주파수 분석으로 화면 재촬영 특유의 모아레 격자 패턴을 탐지합니다. 자연 이미지와 모아레 이미지를 구분하는 것을 Node.js로 사전 검증했습니다(자연 이미지 피크/평균 비율 ≈3.5, 모아레 이미지 ≈150). |

## 스마트컨트랙트 배포 현황

✅ **Sepolia 테스트넷에 실제로 배포 완료했습니다.**

- 컨트랙트 주소: `0xc67D4cBEE20c9bB240E6C9b6Ee0f092f93fcdf7E`
- Etherscan에서 확인: https://sepolia.etherscan.io/address/0xc67D4cBEE20c9bB240E6C9b6Ee0f092f93fcdf7E

### 재현 방법 (다른 팀원이 다시 배포하고 싶을 때)

코딩 없이 클릭만으로 가능해요.

1. [Remix IDE](https://remix.ethereum.org) 접속
2. 왼쪽 파일 탐색기에 `PhotoAuthTimelock.sol` 내용을 붙여넣기
3. 왼쪽 메뉴에서 "Solidity Compiler" → Compile 버튼
4. "Deploy & Run Transactions" → Environment를 "Injected Provider - MetaMask"로 변경 (메타마스크 설치 및 Sepolia 테스트넷 전환 필요)
5. Sepolia 테스트넷 ETH가 없다면 Google Cloud Web3 Faucet 등에서 무료로 받을 수 있어요
6. Deploy 클릭 → 새로 배포된 주소를 기재

## 현재 구현 범위와 한계 (자체 인지)

- ①번 블록 해시 조회는 실제 테스트넷과 통신하지만, 사진 메타데이터에 결합하는 부분은 브라우저 로컬 연산으로 시뮬레이션했습니다.
- ③번 AI 판별은 규칙 기반(FFT 주파수 분석)이며, 실제 서비스에서는 학습 데이터로 정교화된 딥러닝 모델로 고도화가 필요합니다.
- 스마트컨트랙트의 `aiScreenCheckPassed` 파라미터는 현재 누구나 값을 임의로 제출할 수 있는 구조입니다. 실제 서비스에서는 신뢰된 오라클(AI 서버)의 서명을 온체인에서 검증하는 절차가 추가로 필요합니다.

## 참고 자료

- 생성형 AI 조작 사기 관련 보도: 중앙일보(joongang.co.kr/article/25421255), KBS, 연합뉴스TV
- C2PA 콘텐츠 자격증명: [Adobe Content Credentials](https://helpx.adobe.com/kr/creative-cloud/apps/adobe-content-authenticity/content-credentials/overview.html)
