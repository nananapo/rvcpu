#define STRSIZE 12
#define STRPTR  ((int *)(10000))
#define TAILPTR ((int *)(10240))
#define DATAPTR ((int *)(10241))

int main(void)
{
	STRPTR[0] = 'H';
	STRPTR[1] = 'e';
	STRPTR[2] = 'l';
	STRPTR[3] = 'l';
	STRPTR[4] = 'o';
	STRPTR[5] = ' ';
	STRPTR[6] = 'W';
	STRPTR[7] = 'o';
	STRPTR[8] = 'r';
	STRPTR[9] = 'l';
	STRPTR[10]= 'd';
	STRPTR[11]= '!';

	for (int i = 0; i < STRSIZE; i++)
	{
		int dindex = (*TAILPTR + i) % 32;
		DATAPTR[dindex] = STRPTR[i];
	}
	*TAILPTR = (*TAILPTR + STRSIZE) % 32;

	while (1);
}
