#define STRSIZE 13
#define STRPTR  ((volatile int *)(10000))
#define TAILPTR ((volatile int *)(10240))
#define DATAPTR ((volatile int *)(10244))

int main(void)
{
start:
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
	STRPTR[12]= '\n';

	int tail = *TAILPTR;

	for (int i = 0; i < STRSIZE; i++)
	{
		int dindex = (tail + i) % 32;
		DATAPTR[dindex] = STRPTR[i];
	}
	*TAILPTR = (tail + STRSIZE) % 32;

	int count = 0;
	while (count++ < 1000000);
goto start;
}
