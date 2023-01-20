char *str = "Hello World!";
int strsize = 12;

int main(void)
{
	int *tailptr = (void *)10240;
	int *dataptr = (void *)10241;

	for (int i = 0; i < strsize; i++)
	{
		int dindex = (*tailptr + i) % 32;
		dataptr[dindex] = str[i];
	}
	*tailptr = (*tailptr + strsize) % 32;

	while (1);
}
