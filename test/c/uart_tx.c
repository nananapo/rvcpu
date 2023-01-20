int main(void)
{
	int *mapptr = 10240;
	int tail_p = (*mapptr + 1) % 32;
	volatile mapptr[tail_p + 1] = 'K';
	volatile  mapptr[0] = tail_p;
}
