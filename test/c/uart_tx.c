#define STRSIZE 13
#define STRPTR  ((volatile char *)(0x00000800))
#define TAILPTR ((volatile char *)(0xff000100))
#define DATAPTR ((volatile char *)(0xff000000))
#define BUFSIZE 256

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
		int dindex = (tail + i) % 256;
		DATAPTR[dindex] = STRPTR[i];
	}
	*TAILPTR = (tail + STRSIZE) % 256;

    __asm__("li gp,1");

	int count = 0;
	while (count++ < 1000000);
    
    __asm__("li gp,2");
	count = 0;
	while (count++ < 1000000);
goto start;
}
