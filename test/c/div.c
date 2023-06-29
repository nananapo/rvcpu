int main(void)
{
    volatile unsigned long a = 1005552;
    volatile unsigned long b = 16;
    assert(a / b, 62847);
    assert(a % b, 0);
}