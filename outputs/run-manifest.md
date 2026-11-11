# Run manifest

Generated: 2026-11-11 02:45:07 UTC

Commands: scripts/run_tests.sh, scripts/run_benchmarks.sh run1/run2, scripts/run_demo.sh (transparency log + key rotation), scripts/clean_reproduce.sh (fresh copy: full tests + full benchmarks + demos).

## Output files (sha256)

2f89d30e19779ffb2d5e995f37f92e40305efd8c62c6425fbdca55e6d001d031  benchmarks-run1.csv
8fb7b4cc2d5a819a15627e876296049fbdb231eced55d4f0f7404dbd2baddee7  benchmarks-run1.log
259a563d9254e4cb276b174e86f848f9d61217a5b76b3ee69632e151cec00850  benchmarks-run2.csv
68160ae6b6bce31ebe747d9e2bbb3c0464926d2a5421901a2aca4e5ee5600edf  benchmarks-run2.log
6fc57357639ce176dcc27418f77fb581424e338bf0efd94d5551aa29176f0e91  build-opt-cmake.log
86a53cd96e0e7141ee1d8bf9327b76b76dbe6d8006ee8ccaa4191238124c1479  build-opt-install.log
1128d74bf4fe46aebe6763ebf72a2acc993b34ad81d12b236f6b6811540e6a0e  build-opt-make.log
ff8fffde48f95fcd548367b7e578929b3b48c5bd931f0ff57d3f44a25f81c1d9  fresh-clone-benchmarks-run1.csv
aa42e075d860722b981980e7afb052218de4ed74b3be7dcd16db76863c099e86  fresh-clone-benchmarks-run1.log
1facafb68f9dbd757f2d3465cdf10e3c6d1221d395b96a4c07bdb96939b96c3c  fresh-clone-benchmarks-run2.csv
f312b91ceaa54ecf1e813f75d350ffd350606dfa2ff42a5cdefeb91e9fdf06b6  fresh-clone-benchmarks-run2.log
94a10de608266d0e085417f6874581fd930c7df89a0ac2f02670dc55f3fa9480  fresh-clone-rotation-demo.log
07867c9e2dec052011be0dcfe7f2e95f4cea9d81f859cb0ab8ae6b67b402b30f  fresh-clone-rotation-manifest.json
51538ece1c1143c4b061bb8385b51e3604adcdef2f7d131f992c822287167127  fresh-clone-run.log
4a5ef73c8cc56283d9a7eb12fa93a221dee36c0142b00b9390e9e622a599dbf1  fresh-clone-scale-run1.csv
ab1ca165efa557e2914db8080cb6f020eb39a84e147de907433579001a192df0  fresh-clone-scale-run2.csv
75c193650ddfb01015be23485dbccb64b181194c7d839b643a711bd70d2a46cf  fresh-clone-sign-tests.log
b39b81ba6b49163929f7e9646b2d351fa899fc4c50a0a984829d584839c52d9b  fresh-clone-tlog-demo.log
e5da1fcd452672ec1dc768254ca113c8009cff4314ff6f9de69c055b34d3a244  repro-opt-cmake.log
627ed020bdc590c2e1c49325fb12dc12e9c30a66f160d0a6eea6fd5fa1549774  repro-opt-install.log
875d72f691ab0e1468ded8055082f90e8a8dd23bf8f1203fa5b57d104794d100  repro-opt-make.log
8ba5b5282afa03e0770b791f364649c22f7a57df51223340eb4a709d78c4f864  rotation-demo.log
e768461edf1aea2644b82e6d04f1eaf2045c7182b4dc0edb5612c4631f79241e  rotation-manifest.json
35e86f28bffdece880657b7f0fa2cf96a5fe13fd3e3647ba8894c2ebf5fe2cd5  scale-run1.csv
2372b99dafa8651f8bbc6ef5707d55f53d45e08a1ff3f3d5f47a91ddace4108f  scale-run2.csv
7ef361ee990b7d06f35fc198e6fbce9281fa03f861518126dfe94108901ab802  sign-tests.log
f1c25050d59673d5aa6b5d40897694998196e68edbc6c2636acfea6d87fa9396  tlog-demo.log

## Headline results (from logs)

### sign-tests.log
test_summary: alg=ML-DSA-44 checks=8 pass=8 fail=0
RESULT: PASS sigtest ML-DSA-44 checks=8
test_summary: alg=ML-DSA-65 checks=8 pass=8 fail=0
RESULT: PASS sigtest ML-DSA-65 checks=8
test_summary: alg=ML-DSA-87 checks=8 pass=8 fail=0
RESULT: PASS sigtest ML-DSA-87 checks=8
test_summary: alg=SLH_DSA_PURE_SHA2_128S checks=8 pass=8 fail=0
RESULT: PASS sigtest SLH_DSA_PURE_SHA2_128S checks=8
test_summary: alg=SLH_DSA_PURE_SHA2_128F checks=8 pass=8 fail=0
RESULT: PASS sigtest SLH_DSA_PURE_SHA2_128F checks=8
test_summary: alg=SLH_DSA_PURE_SHA2_192S checks=8 pass=8 fail=0
RESULT: PASS sigtest SLH_DSA_PURE_SHA2_192S checks=8
test_summary: alg=SLH_DSA_PURE_SHA2_256S checks=8 pass=8 fail=0
RESULT: PASS sigtest SLH_DSA_PURE_SHA2_256S checks=8
RESULT: PASS sign-tests all_algorithms
### benchmarks-run1.log
bench: alg=ML-DSA-44 n=100 artifact_bytes=503 pk_len=1312 sk_len=2560 sig_len=2420 keygen_median_us=32.6 sign_median_us=83.4 verify_median_us=37.4 verify_ok=100/100
bench: alg=ML-DSA-65 n=100 artifact_bytes=503 pk_len=1952 sk_len=4032 sig_len=3309 keygen_median_us=56.9 sign_median_us=142.2 verify_median_us=60.3 verify_ok=100/100
bench: alg=ML-DSA-87 n=100 artifact_bytes=503 pk_len=2592 sk_len=4896 sig_len=4627 keygen_median_us=82.1 sign_median_us=161.9 verify_median_us=85.2 verify_ok=100/100
bench: alg=SLH_DSA_PURE_SHA2_128S n=20 artifact_bytes=503 pk_len=32 sk_len=64 sig_len=7856 keygen_median_us=95514.5 sign_median_us=720164.3 verify_median_us=709.1 verify_ok=20/20
bench: alg=SLH_DSA_PURE_SHA2_128F n=20 artifact_bytes=503 pk_len=32 sk_len=64 sig_len=17088 keygen_median_us=1471.2 sign_median_us=34618.5 verify_median_us=2158.6 verify_ok=20/20
bench: alg=SLH_DSA_PURE_SHA2_192S n=20 artifact_bytes=503 pk_len=48 sk_len=96 sig_len=16224 keygen_median_us=137094.8 sign_median_us=1269114.6 verify_median_us=987.6 verify_ok=20/20
bench: alg=SLH_DSA_PURE_SHA2_256S n=20 artifact_bytes=503 pk_len=64 sk_len=128 sig_len=29792 keygen_median_us=89972.0 sign_median_us=1127361.0 verify_median_us=1589.1 verify_ok=20/20
### benchmarks-run2.log
bench: alg=ML-DSA-44 n=100 artifact_bytes=503 pk_len=1312 sk_len=2560 sig_len=2420 keygen_median_us=33.0 sign_median_us=98.5 verify_median_us=37.7 verify_ok=100/100
bench: alg=ML-DSA-65 n=100 artifact_bytes=503 pk_len=1952 sk_len=4032 sig_len=3309 keygen_median_us=57.3 sign_median_us=144.1 verify_median_us=60.7 verify_ok=100/100
bench: alg=ML-DSA-87 n=100 artifact_bytes=503 pk_len=2592 sk_len=4896 sig_len=4627 keygen_median_us=82.4 sign_median_us=162.8 verify_median_us=85.2 verify_ok=100/100
bench: alg=SLH_DSA_PURE_SHA2_128S n=20 artifact_bytes=503 pk_len=32 sk_len=64 sig_len=7856 keygen_median_us=93849.0 sign_median_us=716569.9 verify_median_us=692.7 verify_ok=20/20
bench: alg=SLH_DSA_PURE_SHA2_128F n=20 artifact_bytes=503 pk_len=32 sk_len=64 sig_len=17088 keygen_median_us=1475.8 sign_median_us=34678.1 verify_median_us=2183.6 verify_ok=20/20
bench: alg=SLH_DSA_PURE_SHA2_192S n=20 artifact_bytes=503 pk_len=48 sk_len=96 sig_len=16224 keygen_median_us=137758.6 sign_median_us=1271399.2 verify_median_us=1010.4 verify_ok=20/20
bench: alg=SLH_DSA_PURE_SHA2_256S n=20 artifact_bytes=503 pk_len=64 sk_len=128 sig_len=29792 keygen_median_us=90266.4 sign_median_us=1125649.1 verify_median_us=1521.0 verify_ok=20/20
### tlog-demo.log
tlog_summary: entries=5 proof_verified=1 tamper_detected=1 stale_proof_rejected=1
RESULT: PASS tlog entries=5
### rotation-demo.log
RESULT: PASS rotation
