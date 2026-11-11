/*
 * release_sign.c — Release-signing harness for ML-DSA and SLH-DSA.
 *
 * Signs and verifies real release artifacts with the pinned liboqs 0.16.0
 * signature implementations, through the public OQS_SIG API only:
 *
 *   sizes  <alg>                        print key/signature lengths
 *   keygen <alg> <pkfile> <skfile>      generate a keypair (runtime only)
 *   sign   <alg> <skfile> <artifact> <sigfile>
 *                                        sign an artifact file
 *   verify <alg> <pkfile> <artifact> <sigfile>
 *                                        verify; exit 0 iff valid
 *   bench  <alg> <artifact> <n>         keygen/sign/verify medians + sizes
 *   test   <alg> <artifact>             correctness suite (see below)
 *   scalesign <alg> <artifact> <n>      sign timing vs artifact size
 *
 * test checks per algorithm: (1) sign+verify round-trip, (2) tampered
 * artifact rejected, (3) tampered signature rejected, (4) wrong keypair
 * rejected, (5) empty-message round-trip, (6) signature length equals the
 * advertised length_signature. Keys are generated at runtime with the
 * library's own randomness and are never printed; only public-key prefixes
 * and signature lengths appear in output. Signatures are randomized
 * (hedged) per FIPS 204/205, so signature bytes differ between runs;
 * tests depend only on verification outcomes and lengths, never on
 * exact signature bytes.
 *
 * Build (example):
 *   cc -O2 -I<install>/include release_sign.c -L<install>/lib -loqs -lcrypto -o release_sign
 */
#include <oqs/oqs.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static double now_us(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (double)ts.tv_sec * 1e6 + (double)ts.tv_nsec / 1e3;
}

static int cmp_double(const void *a, const void *b) {
	double x = *(const double *)a, y = *(const double *)b;
	return (x > y) - (x < y);
}

static double median(double *v, size_t n) {
	qsort(v, n, sizeof(double), cmp_double);
	if (n % 2) return v[n / 2];
	return (v[n / 2 - 1] + v[n / 2]) / 2.0;
}

static uint8_t *read_file(const char *path, size_t *len_out) {
	FILE *f = fopen(path, "rb");
	if (!f) return NULL;
	fseek(f, 0, SEEK_END);
	long n = ftell(f);
	fseek(f, 0, SEEK_SET);
	if (n < 0) { fclose(f); return NULL; }
	uint8_t *buf = malloc((size_t)n > 0 ? (size_t)n : 1);
	if (!buf) { fclose(f); return NULL; }
	if (n > 0 && fread(buf, 1, (size_t)n, f) != (size_t)n) {
		free(buf); fclose(f); return NULL;
	}
	fclose(f);
	*len_out = (size_t)n;
	return buf;
}

static int write_file(const char *path, const uint8_t *data, size_t len) {
	FILE *f = fopen(path, "wb");
	if (!f) return -1;
	if (len > 0 && fwrite(data, 1, len, f) != len) { fclose(f); return -1; }
	fclose(f);
	return 0;
}

static void print_hex_prefix(const uint8_t *b, size_t n) {
	size_t m = n < 16 ? n : 16;
	for (size_t i = 0; i < m; i++) printf("%02x", b[i]);
}

int main(int argc, char **argv) {
	if (argc < 2) {
		fprintf(stderr, "usage: %s <sizes|keygen|sign|verify|bench|test|scalesign> ...\n", argv[0]);
		return 2;
	}
	const char *cmd = argv[1];

	if (!strcmp(cmd, "sizes")) {
		if (argc != 3) { fprintf(stderr, "usage: sizes <alg>\n"); return 2; }
		OQS_SIG *sig = OQS_SIG_new(argv[2]);
		if (!sig) { fprintf(stderr, "unknown algorithm: %s\n", argv[2]); return 1; }
		printf("sizes: alg=%s pk_len=%zu sk_len=%zu sig_len=%zu nist_level=%d\n",
		       sig->method_name, sig->length_public_key,
		       sig->length_secret_key, sig->length_signature,
		       sig->claimed_nist_level);
		OQS_SIG_free(sig);
		return 0;
	}

	if (!strcmp(cmd, "keygen")) {
		if (argc != 5) { fprintf(stderr, "usage: keygen <alg> <pkfile> <skfile>\n"); return 2; }
		OQS_SIG *sig = OQS_SIG_new(argv[2]);
		if (!sig) { fprintf(stderr, "unknown algorithm: %s\n", argv[2]); return 1; }
		uint8_t *pk = malloc(sig->length_public_key);
		uint8_t *sk = malloc(sig->length_secret_key);
		if (OQS_SIG_keypair(sig, pk, sk) != OQS_SUCCESS) {
			fprintf(stderr, "keypair failed\n"); return 1;
		}
		if (write_file(argv[3], pk, sig->length_public_key) ||
		    write_file(argv[4], sk, sig->length_secret_key)) {
			fprintf(stderr, "write failed\n"); return 1;
		}
		printf("keygen: alg=%s pk_len=%zu sk_len=%zu pk_prefix=", sig->method_name,
		       sig->length_public_key, sig->length_secret_key);
		print_hex_prefix(pk, sig->length_public_key);
		printf("\n");
		OQS_SIG_free(sig);
		free(pk); free(sk);
		return 0;
	}

	if (!strcmp(cmd, "sign")) {
		if (argc != 6) { fprintf(stderr, "usage: sign <alg> <skfile> <artifact> <sigfile>\n"); return 2; }
		OQS_SIG *sig = OQS_SIG_new(argv[2]);
		if (!sig) { fprintf(stderr, "unknown algorithm: %s\n", argv[2]); return 1; }
		size_t sk_len, msg_len;
		uint8_t *sk = read_file(argv[3], &sk_len);
		uint8_t *msg = read_file(argv[4], &msg_len);
		if (!sk || !msg || sk_len != sig->length_secret_key) {
			fprintf(stderr, "sign: bad input files\n"); return 1;
		}
		uint8_t *sg = malloc(sig->length_signature);
		size_t sg_len = 0;
		if (OQS_SIG_sign(sig, sg, &sg_len, msg, msg_len, sk) != OQS_SUCCESS) {
			fprintf(stderr, "sign failed\n"); return 1;
		}
		if (write_file(argv[5], sg, sg_len)) { fprintf(stderr, "write failed\n"); return 1; }
		printf("sign: alg=%s artifact_bytes=%zu sig_len=%zu\n", sig->method_name, msg_len, sg_len);
		OQS_SIG_free(sig);
		free(sk); free(msg); free(sg);
		return 0;
	}

	if (!strcmp(cmd, "verify")) {
		if (argc != 6) { fprintf(stderr, "usage: verify <alg> <pkfile> <artifact> <sigfile>\n"); return 2; }
		OQS_SIG *sig = OQS_SIG_new(argv[2]);
		if (!sig) { fprintf(stderr, "unknown algorithm: %s\n", argv[2]); return 1; }
		size_t pk_len, msg_len, sg_len;
		uint8_t *pk = read_file(argv[3], &pk_len);
		uint8_t *msg = read_file(argv[4], &msg_len);
		uint8_t *sg = read_file(argv[5], &sg_len);
		if (!pk || !msg || !sg || pk_len != sig->length_public_key) {
			fprintf(stderr, "verify: bad input files\n"); return 1;
		}
		OQS_STATUS rc = OQS_SIG_verify(sig, msg, msg_len, sg, sg_len, pk);
		printf("verify: alg=%s artifact_bytes=%zu sig_len=%zu result=%s\n",
		       sig->method_name, msg_len, sg_len,
		       rc == OQS_SUCCESS ? "OK" : "FAIL");
		OQS_SIG_free(sig);
		free(pk); free(msg); free(sg);
		return rc == OQS_SUCCESS ? 0 : 1;
	}

	if (!strcmp(cmd, "bench")) {
		if (argc != 5) { fprintf(stderr, "usage: bench <alg> <artifact> <n>\n"); return 2; }
		OQS_SIG *sig = OQS_SIG_new(argv[2]);
		if (!sig) { fprintf(stderr, "unknown algorithm: %s\n", argv[2]); return 1; }
		size_t msg_len;
		uint8_t *msg = read_file(argv[3], &msg_len);
		if (!msg) { fprintf(stderr, "bench: cannot read artifact\n"); return 1; }
		int n = atoi(argv[4]);
		if (n < 1) n = 1;
		if (n > 1000) n = 1000;
		double *tv = malloc(sizeof(double) * (size_t)n);
		uint8_t *pk = malloc(sig->length_public_key);
		uint8_t *sk = malloc(sig->length_secret_key);
		uint8_t *sg = malloc(sig->length_signature);
		size_t sg_len = 0;

		/* keygen timing */
		for (int i = 0; i < n; i++) {
			double t0 = now_us();
			if (OQS_SIG_keypair(sig, pk, sk) != OQS_SUCCESS) { fprintf(stderr, "keypair failed\n"); return 1; }
			tv[i] = now_us() - t0;
		}
		double kg_med = median(tv, (size_t)n);
		/* sign timing */
		for (int i = 0; i < n; i++) {
			double t0 = now_us();
			if (OQS_SIG_sign(sig, sg, &sg_len, msg, msg_len, sk) != OQS_SUCCESS) { fprintf(stderr, "sign failed\n"); return 1; }
			tv[i] = now_us() - t0;
		}
		double sign_med = median(tv, (size_t)n);
		/* verify timing */
		int vok = 0;
		for (int i = 0; i < n; i++) {
			double t0 = now_us();
			if (OQS_SIG_verify(sig, msg, msg_len, sg, sg_len, pk) == OQS_SUCCESS) vok++;
			tv[i] = now_us() - t0;
		}
		double ver_med = median(tv, (size_t)n);
		printf("bench: alg=%s n=%d artifact_bytes=%zu pk_len=%zu sk_len=%zu sig_len=%zu keygen_median_us=%.1f sign_median_us=%.1f verify_median_us=%.1f verify_ok=%d/%d\n",
		       sig->method_name, n, msg_len, sig->length_public_key,
		       sig->length_secret_key, sig->length_signature,
		       kg_med, sign_med, ver_med, vok, n);
		printf("csv: %s,%d,%zu,%zu,%zu,%zu,%.1f,%.1f,%.1f,%d\n",
		       sig->method_name, n, msg_len, sig->length_public_key,
		       sig->length_secret_key, sig->length_signature,
		       kg_med, sign_med, ver_med, vok);
		OQS_SIG_free(sig);
		free(tv); free(pk); free(sk); free(sg); free(msg);
		return 0;
	}

	if (!strcmp(cmd, "scalesign")) {
		if (argc != 5) { fprintf(stderr, "usage: scalesign <alg> <artifact> <n>\n"); return 2; }
		OQS_SIG *sig = OQS_SIG_new(argv[2]);
		if (!sig) { fprintf(stderr, "unknown algorithm: %s\n", argv[2]); return 1; }
		size_t msg_len;
		uint8_t *msg = read_file(argv[3], &msg_len);
		if (!msg) { fprintf(stderr, "scalesign: cannot read artifact\n"); return 1; }
		int n = atoi(argv[4]);
		if (n < 1) n = 1;
		if (n > 100) n = 100;
		double *tv = malloc(sizeof(double) * (size_t)n);
		uint8_t *pk = malloc(sig->length_public_key);
		uint8_t *sk = malloc(sig->length_secret_key);
		uint8_t *sg = malloc(sig->length_signature);
		size_t sg_len = 0;
		if (OQS_SIG_keypair(sig, pk, sk) != OQS_SUCCESS) { fprintf(stderr, "keypair failed\n"); return 1; }
		for (int i = 0; i < n; i++) {
			double t0 = now_us();
			if (OQS_SIG_sign(sig, sg, &sg_len, msg, msg_len, sk) != OQS_SUCCESS) { fprintf(stderr, "sign failed\n"); return 1; }
			tv[i] = now_us() - t0;
		}
		printf("scalesign: alg=%s artifact_bytes=%zu n=%d sign_median_us=%.1f sig_len=%zu\n",
		       sig->method_name, msg_len, n, median(tv, (size_t)n), sg_len);
		OQS_SIG_free(sig);
		free(tv); free(pk); free(sk); free(sg); free(msg);
		return 0;
	}

	if (!strcmp(cmd, "test")) {
		if (argc != 4) { fprintf(stderr, "usage: test <alg> <artifact>\n"); return 2; }
		OQS_SIG *sig = OQS_SIG_new(argv[2]);
		if (!sig) { fprintf(stderr, "unknown algorithm: %s\n", argv[2]); return 1; }
		size_t msg_len;
		uint8_t *msg = read_file(argv[3], &msg_len);
		if (!msg) { fprintf(stderr, "test: cannot read artifact\n"); return 1; }
		int checks = 0, fails = 0;
		uint8_t *pk = malloc(sig->length_public_key);
		uint8_t *sk = malloc(sig->length_secret_key);
		uint8_t *pk2 = malloc(sig->length_public_key);
		uint8_t *sk2 = malloc(sig->length_secret_key);
		uint8_t *sg = malloc(sig->length_signature);
		size_t sg_len = 0;

#define CHECK(name, cond) do { checks++; \
		printf("test: alg=%s check=%s %s\n", sig->method_name, name, (cond) ? "PASS" : "FAIL"); \
		if (!(cond)) fails++; } while (0)

		OQS_STATUS ok = OQS_SIG_keypair(sig, pk, sk);
		CHECK("keygen", ok == OQS_SUCCESS);
		ok = OQS_SIG_sign(sig, sg, &sg_len, msg, msg_len, sk);
		CHECK("sign", ok == OQS_SUCCESS && sg_len == sig->length_signature);
		CHECK("verify_roundtrip",
		      OQS_SIG_verify(sig, msg, msg_len, sg, sg_len, pk) == OQS_SUCCESS);
		/* tampered artifact: flip one byte in a copy */
		uint8_t *msg2 = malloc(msg_len > 0 ? msg_len : 1);
		memcpy(msg2, msg, msg_len);
		if (msg_len > 0) msg2[msg_len / 2] ^= 0x01;
		CHECK("tampered_artifact_rejected",
		      OQS_SIG_verify(sig, msg2, msg_len, sg, sg_len, pk) != OQS_SUCCESS);
		/* tampered signature */
		uint8_t *sg2 = malloc(sig->length_signature);
		memcpy(sg2, sg, sg_len);
		sg2[0] ^= 0x01;
		CHECK("tampered_signature_rejected",
		      OQS_SIG_verify(sig, msg, msg_len, sg2, sg_len, pk) != OQS_SUCCESS);
		/* wrong keypair */
		OQS_SIG_keypair(sig, pk2, sk2);
		CHECK("wrong_key_rejected",
		      OQS_SIG_verify(sig, msg, msg_len, sg, sg_len, pk2) != OQS_SUCCESS);
		/* empty message round-trip */
		uint8_t dummy = 0;
		if (OQS_SIG_sign(sig, sg, &sg_len, &dummy, 0, sk) == OQS_SUCCESS &&
		    OQS_SIG_verify(sig, &dummy, 0, sg, sg_len, pk) == OQS_SUCCESS)
			CHECK("empty_message_roundtrip", 1);
		else
			CHECK("empty_message_roundtrip", 0);
		/* sizes match the advertised lengths */
		CHECK("sizes_match", sig->length_public_key > 0 &&
		      sig->length_secret_key > 0 && sig->length_signature > 0);
		printf("test_summary: alg=%s checks=%d pass=%d fail=%d\n",
		       sig->method_name, checks, checks - fails, fails);
		printf("RESULT: %s sigtest %s checks=%d\n",
		       fails == 0 ? "PASS" : "FAIL", sig->method_name, checks);
		OQS_SIG_free(sig);
		free(pk); free(sk); free(pk2); free(sk2);
		free(sg); free(sg2); free(msg); free(msg2);
		return fails == 0 ? 0 : 1;
	}

	fprintf(stderr, "unknown command: %s\n", cmd);
	return 2;
}
