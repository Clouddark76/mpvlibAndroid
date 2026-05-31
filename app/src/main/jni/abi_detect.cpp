#include <jni.h>

#ifdef __aarch64__
#include <sys/auxv.h>
#include <asm/hwcap.h>
#endif

// HWCAP2 flags for ARMv9 features — define if not in headers (older NDK/kernel headers)
#ifndef HWCAP2_SVE2
#define HWCAP2_SVE2 (1UL << 1)
#endif
#ifndef HWCAP2_I8MM
#define HWCAP2_I8MM (1UL << 13)
#endif
#ifndef HWCAP2_SME
#define HWCAP2_SME (1UL << 23)
#endif
#ifndef HWCAP2_BF16
#define HWCAP2_BF16 (1UL << 14)
#endif

extern "C" {

/**
 * Native ARM v9a capability detection using getauxval(AT_HWCAP2).
 * This is the most reliable method on Linux/Android — directly queries the kernel
 * for CPU feature flags without parsing /proc/cpuinfo.
 *
 * Returns true if the CPU supports SVE2 or I8MM (both are mandatory ARMv9 features).
 * Compatible SoCs: Cortex-X3+, Cortex-A720+, Snapdragon 8 Gen 2+, Dimensity 9200+, Exynos 2400+
 */
JNIEXPORT jboolean JNICALL
Java_is_xyz_mpv_AbiDetector_nativeCheckSve2Support(JNIEnv*, jclass) {
#ifdef __aarch64__
    unsigned long hwcap2 = getauxval(AT_HWCAP2);
    // SVE2 is the defining mandatory feature of ARMv9-A
    // I8MM (Int8 Matrix Multiply) is also mandatory in ARMv9
    return (jboolean)((hwcap2 & HWCAP2_SVE2) || (hwcap2 & HWCAP2_I8MM));
#else
    return JNI_FALSE;
#endif
}

/**
 * Returns a bitmask of detected ARM features for diagnostic purposes.
 * Bit 0: SVE2
 * Bit 1: I8MM
 * Bit 2: SME
 * Bit 3: BF16
 */
JNIEXPORT jint JNICALL
Java_is_xyz_mpv_AbiDetector_nativeGetArmFeatures(JNIEnv*, jclass) {
#ifdef __aarch64__
    unsigned long hwcap2 = getauxval(AT_HWCAP2);
    jint features = 0;
    if (hwcap2 & HWCAP2_SVE2) features |= (1 << 0);
    if (hwcap2 & HWCAP2_I8MM) features |= (1 << 1);
    if (hwcap2 & HWCAP2_SME)  features |= (1 << 2);
    if (hwcap2 & HWCAP2_BF16) features |= (1 << 3);
    return features;
#else
    return 0;
#endif
}

} // extern "C"
