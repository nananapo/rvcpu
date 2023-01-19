int main(void)
{
	int *mapptr = 10240;
	int tail_p = (*mapptr + 1) % 32;
	mapptr[tail_p + 1] = 'K';
	mapptr[0] = tail_p;
}
