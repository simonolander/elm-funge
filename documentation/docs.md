# Manick

## Objective
Manick is a puzzle game where each level requires you to write a program to solve it. 

### The program
The program is not written in text, but as a set of instructions placed on a two dimensional board. The program pointer can move up, down, left, and right across the board and will execute any instruction it passes over regardless of current direction.

A correct program must
1. Not produce any exceptions
1. Produce the correct output for the given level
1. Terminate

Most levels require the program to read and process some input in order to produce the correct output. As you read data values from the input, the values appear in the stack. The stack is the working memory of the program.

#### The data values 
The system uses signed 16 bit integers (-32768 to 32767) for all operations, and this is also the values that are stored in the in input, stack, and output. If a result of a computation is too large to fit in 16 bit it overflows without warning, meaning that e.g. `32767 + 1 = -32768`, and `20000 + 20000 = -25536`.

#### The input
The input contains data that you typically need to read in order to complete the task. The read instruction is used to read one value from the input and push it to the stack. If the input is empty, a zero will be read instead. 

#### The stack
The stack is the working memory of the program. Instructions typically operate on the top values of the stack. There is no limit on the size of the stack. Reading a value from an empty stack will return a zero.

#### The output
The output is where the program writes the result of the execution. It contains two columns: the expected output and the actual output. As the program outputs more values they will be appended to the actual output. Incorrect output will be highlighted in red.

#### The board
The board is the rectangular grid that contains all the instructions of the program.

#### The instruction pointer
The instruction pointer is the current head of execution in a running program. As it moves across the board, the current cell that it points to is highlighted in gray. The instruction pointer always has a direction, `up`, `left`, `right` or `down`. After executing the instruction in the current position, it will move one cell in its current direction. If it passes over the edge of the board it will loop around to the other side of the board.

#### The instructions
There is a number of different instructions available for you to construct your program. They typically do one of the following things:
- Read a value from the input
- Write a value to the output
- Change direction of the instruction pointer
- Operate on the values in the stack
- Terminate the program

### The levels
Each level consists of the following:

- A description of the objective
- An initial board
- A set of instructions tools that you are allowed to use
- One or several test suites

#### The initial board
The board is where you construct your program. Each square on the board may contain an instruction, and as the program pointer moves across the board the program will execute every 
 
## 
