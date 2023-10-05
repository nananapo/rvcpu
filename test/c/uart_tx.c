#define STRSIZE 13
#define UART_TX_PTR ((volatile int *)(0xff000000))

int main(void)
{
start:
	*UART_TX_PTR = 'H';
	*UART_TX_PTR = 'e';
	*UART_TX_PTR = 'l';
	*UART_TX_PTR = 'l';
	*UART_TX_PTR = 'o';
	*UART_TX_PTR = ' ';
	*UART_TX_PTR = 'W';
	*UART_TX_PTR = 'o';
	*UART_TX_PTR = 'r';
	*UART_TX_PTR = 'l';
	*UART_TX_PTR = 'd';
	*UART_TX_PTR = '!';
	*UART_TX_PTR = '\n';
	volatile int count = 0;
	while (count++ < 1000000);
goto start;
}
