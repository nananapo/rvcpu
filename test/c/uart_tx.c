char *str = (void *)10000;
#define STRSIZE 12;

int main(void)
{
	str[0] = "H";
	str[1] = "e";
	str[2] = "l";
	str[3] = "l";
	str[4] = "o";
	str[5] = " ";
	str[6] = "W";
	str[7] = "o";
	str[8] = "r";
	str[9] = "l";
	str[10]= "d";
	str[11]= "!";

	int *tailptr = (void *)10240;
	int *dataptr = (void *)10241;

	for (int i = 0; i < STRSIZE; i++)
	{
		int dindex = (*tailptr + i) % 32;
		dataptr[dindex] = str[i];
	}
	*tailptr = (*tailptr + STRSIZE) % 32;

	while (1);
}
