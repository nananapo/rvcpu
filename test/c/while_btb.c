int main(void)
{
    volatile int k = 0;
    for (int i = 0; i < 100; i++)
    {
        k = i;
    }
}
