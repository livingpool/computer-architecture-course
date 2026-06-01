#include <stdint.h>

volatile int result_sink;

int main(void) {
    register int a = 33;
    register int b = 66;
    register int c = 99;
    register int d = 132;
    register int s = 0;
    register int t = 0;
    register int u = 0;
    register int v = 0;
    register int w = 0;
    register int x = 0;
    register int y = 0;
    register int z = 0;
    register int r = 0;

    for (register int i = 1; i <= 100; i++) {
        s = a + b;
        t = c + d;
        u = a - c;
        v = b - d;
        w = a * b;
        x = c * d;
        y = a ^ d;
        z = b ^ c;
        r = a + b + c + d;
    }

    result_sink = s + t + u + v + w + x + y + z + r;

    return 0;
}
