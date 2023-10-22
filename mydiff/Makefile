NAME=mydiff

$(NAME):
	gcc -c -o main.o main.c
	gcc main.o -o $(NAME)

clean:
	rm -f main.o

fclean:	clean
	rm -f mydiff

re: fclean $(NAME)

.PHONY: clean fclean re
