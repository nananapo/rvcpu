#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#define LINEBUF 1024

void writemore(int fd)
{
	int res;
	char buf;

	while (1)
	{
		res = read(fd, &buf, 1);
		if (res == 0 || res < 0)
			return;
		if (buf == '\n')
			return;
		printf("%c", buf);
	}
}

int openfile(char *file)
{
	if (strlen(file) == 1 && file[0] == '-')
	{
		return 0;
	}
	else
	{
		int  fd = open(file, O_RDONLY);
		if (fd < 0)
		{
			printf("failed to open %s\n", file);
			exit(1);
		}
		return fd;
	}
}

int main(int argc, char **argv)
{
	int 				fd1;
	int 				fd2;
	unsigned long long 	width_count = 0;
	unsigned long long 	line_count = 1;
	int 				readres1;
	int 				readres2;
	char 				linebuf[LINEBUF + 1];
	unsigned char 		buf1;
	unsigned char 		buf2;

	if (argc != 3)
	{
		printf("Usage : %s file1 file2\n", argv[0]);
		exit(1);
	}

	fd1 = openfile(argv[1]);
	fd2 = openfile(argv[2]);
	linebuf[0] = '\0';

	while (1)
	{
		readres1 = read(fd1, &buf1, 1);
		readres2 = read(fd2, &buf2, 1);

		// nodiff
		if (readres1 == readres2 && readres2 == 0)
		{
			exit(0);
		}

		if (readres1 < 0 || readres2 < 0)
		{
			printf("error while reading files\n");
			exit(1);
		}

		if (readres1 == 0 || readres2 == 0)
		{
			printf("%lld\n%s\n %c short end", line_count, linebuf, readres1 == 0 ? '<' : '>');
		}

		if (buf1 != buf2)
		{
			printf("%lld:%lld\n", line_count, width_count);
			printf("< %s%c", linebuf, buf1);
			writemore(fd1);
			printf("\n");
			printf("> %s%c", linebuf, buf2);
			writemore(fd2);
			printf("\n");
			exit(0);
		}

		if (buf1 == '\n')
		{
			width_count = 0;
			linebuf[0] = '\0';
			line_count++;
		}
		else
		{
			if (width_count != LINEBUF)
			{
				linebuf[width_count] = buf1;
				linebuf[width_count + 1] = '\0';
			}
			width_count++;
		}
	}
}
