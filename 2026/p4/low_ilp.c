#include <stdint.h>
#include <stdio.h>

volatile uint64_t sink;

__attribute__((noinline)) uint64_t pipeline_bubbles_raw(uint64_t x) {
    // Long dependency chain: every instruction depends on the previous result.
    // This should create visible scheduler wait cycles / pipeline bubbles.
    x = x * 3 + 1;
    x = x * 3 + 1;
    x = x * 3 + 1;
    x = x * 3 + 1;
    x = x * 3 + 1;
    x = x * 3 + 1;
    x = x * 3 + 1;
    x = x * 3 + 1;
    return x;
}

__attribute__((noinline)) uint64_t register_renaming_demo(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
    // These independent temporaries encourage the compiler to reuse architectural
    // registers in the generated assembly.
    //
    // In llvm-mca, look for repeated writes to the same register without stalls.
    // That is evidence that WAW/WAR false dependencies are being removed by
    // register renaming.
    uint64_t t0 = a + b;
    uint64_t t1 = c + d;
    uint64_t t2 = a * 3;
    uint64_t t3 = b * 5;
    uint64_t t4 = c * 7;
    uint64_t t5 = d * 9;
    return t0 + t1 + t2 + t3 + t4 + t5;
}

__attribute__((noinline)) uint64_t control_hazard_demo(uint64_t x, uint64_t n) {
    uint64_t sum = 0;
    for (uint64_t i = 0; i < n; i++) {
        if (x & 1) {
            sum += x;
        } else {
            sum -= x;
        }
        x = x * 1103515245 + 12345;
    }
    sink = sum;
    return sum;
}

int main(void) {
    uint64_t a = pipeline_bubbles_raw(10);
    uint64_t b = register_renaming_demo(5, 6, 7, 8);
    uint64_t c = control_hazard_demo(1, 5);

    sink = a + b;
    printf("%llu\n", (unsigned long long)sink);

    return 0;
}
