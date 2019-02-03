insert into boards set
  id = 1,
  width = 4,
  height = 4;
insert into levels set
  id = 1,
  uuid = uuid(),
  external_id = '88c653c6c3a5b5e7',
  name = 'One, two, three',
  author_id = null,
  initial_board_id = 1;
call create_description(1, "> Output the numbers 1, 2, and 3");

call create_output(1, 1);
call create_output(1, 2);
call create_output(1, 3);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (1, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 1,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (1, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (1, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (1, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (1, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (1, @instruction_tool_id);
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (1, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 1,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );

insert into boards set
  id = 2,
  width = 4,
  height = 4;
insert into levels set
  id = 2,
  uuid = uuid(),
  external_id = '42fe70779bd30656',
  name = 'Double the fun',
  author_id = null,
  initial_board_id = 2;
call create_description(2, "> Read a number n from input");
call create_description(2, "> Output n * 2");
call create_description(2, "The last input is 0 and should not be printed");
call create_input(2, 1);
call create_input(2, 8);
call create_input(2, 19);
call create_input(2, 3);
call create_input(2, 5);
call create_input(2, 31);
call create_input(2, 9);
call create_input(2, 0);
call create_output(2, 2);
call create_output(2, 16);
call create_output(2, 38);
call create_output(2, 6);
call create_output(2, 10);
call create_output(2, 62);
call create_output(2, 18);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (2, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 2,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (2, @instruction_tool_id);
call create_instruction('Add', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (2, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (2, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (2, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (2, @instruction_tool_id);
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (2, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 2,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );

insert into boards set
  id = 3,
  width = 7,
  height = 7;
insert into levels set
  id = 3,
  uuid = uuid(),
  external_id = 'e2f96c5345e5f1f6',
  name = 'Count down',
  author_id = null,
  initial_board_id = 3;
call create_description(3, "> Read a number n from input");
call create_description(3, "> Output all the numbers from n to 0");
call create_description(3, "The last input is 0 and should not be printed");
call create_input(3, 7);
call create_input(3, 3);
call create_input(3, 10);
call create_input(3, 0);
call create_output(3, 7);
call create_output(3, 6);
call create_output(3, 5);
call create_output(3, 4);
call create_output(3, 3);
call create_output(3, 2);
call create_output(3, 1);
call create_output(3, 0);
call create_output(3, 3);
call create_output(3, 2);
call create_output(3, 1);
call create_output(3, 0);
call create_output(3, 10);
call create_output(3, 9);
call create_output(3, 8);
call create_output(3, 7);
call create_output(3, 6);
call create_output(3, 5);
call create_output(3, 4);
call create_output(3, 3);
call create_output(3, 2);
call create_output(3, 1);
call create_output(3, 0);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (3, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 3,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (3, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (3, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (3, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (3, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (3, @instruction_tool_id);
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (3, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 3,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );

insert into boards set
  id = 4,
  width = 7,
  height = 7;
insert into levels set
  id = 4,
  uuid = uuid(),
  external_id = 'c2003520d988f8d0',
  name = 'Some sums',
  author_id = null,
  initial_board_id = 4;
call create_description(4, "> Read two numbers a and b from input");
call create_description(4, "> Output a + b");
call create_description(4, "The last input is 0 and should not be printed");
call create_input(4, 1);
call create_input(4, 5);
call create_input(4, 13);
call create_input(4, 10);
call create_input(4, 11);
call create_input(4, 10);
call create_input(4, 8);
call create_input(4, 8);
call create_input(4, 0);
call create_output(4, 6);
call create_output(4, 23);
call create_output(4, 21);
call create_output(4, 16);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 4,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 4,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (4, @instruction_tool_id);

insert into boards set
  id = 5,
  width = 5,
  height = 5;
insert into levels set
  id = 5,
  uuid = uuid(),
  external_id = 'd3c077ea5033222c',
  name = 'Signal amplifier',
  author_id = null,
  initial_board_id = 5;
call create_description(5, "> Read a number x from the input");
call create_description(5, "> Output x + 10");
call create_description(5, "The last input is 0 should not be outputed");
call create_input(5, 24);
call create_input(5, 145);
call create_input(5, 49);
call create_input(5, 175);
call create_input(5, 166);
call create_input(5, 94);
call create_input(5, 38);
call create_input(5, 90);
call create_input(5, 165);
call create_input(5, 211);
call create_input(5, 0);
call create_output(5, 34);
call create_output(5, 155);
call create_output(5, 59);
call create_output(5, 185);
call create_output(5, 176);
call create_output(5, 104);
call create_output(5, 48);
call create_output(5, 100);
call create_output(5, 175);
call create_output(5, 221);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 5,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 5,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (5, @instruction_tool_id);

insert into boards set
  id = 6,
  width = 7,
  height = 7;
insert into levels set
  id = 6,
  uuid = uuid(),
  external_id = '1a3c6d6a80769a07',
  name = 'One minus the other',
  author_id = null,
  initial_board_id = 6;
call create_description(6, "> Read two numbers a and b from input");
call create_description(6, "> Output a - b");
call create_description(6, "The last input is 0 and should not be printed");
call create_input(6, 18);
call create_input(6, 4);
call create_input(6, 9);
call create_input(6, 17);
call create_input(6, 13);
call create_input(6, 13);
call create_input(6, 12);
call create_input(6, 1);
call create_input(6, 17);
call create_input(6, 3);
call create_input(6, 0);
call create_output(6, 14);
call create_output(6, -8);
call create_output(6, 0);
call create_output(6, 11);
call create_output(6, 14);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 6,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 6,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (6, @instruction_tool_id);

insert into boards set
  id = 7,
  width = 8,
  height = 8;
insert into levels set
  id = 7,
  uuid = uuid(),
  external_id = '3ee1f15ae601fc94',
  name = 'Powers of two',
  author_id = null,
  initial_board_id = 7;
call create_description(7, "> Read a number n from input");
call create_description(7, "> Output 2^n ");
call create_description(7, "The last input is 0 and should not be printed");
call create_input(7, 1);
call create_input(7, 4);
call create_input(7, 3);
call create_input(7, 2);
call create_input(7, 5);
call create_input(7, 6);
call create_input(7, 0);
call create_output(7, 2);
call create_output(7, 16);
call create_output(7, 8);
call create_output(7, 4);
call create_output(7, 32);
call create_output(7, 64);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 7,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 7,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (7, @instruction_tool_id);

insert into boards set
  id = 8,
  width = 8,
  height = 8;
insert into levels set
  id = 8,
  uuid = uuid(),
  external_id = '24c7efb5c41f8f8f',
  name = 'Triangular numbers',
  author_id = null,
  initial_board_id = 8;
call create_description(8, "> Read a number n from input");
call create_description(8, "> Output n*(n+1)/2 ");
call create_description(8, "The last input is 0 and should not be printed");
call create_input(8, 5);
call create_input(8, 13);
call create_input(8, 7);
call create_input(8, 11);
call create_input(8, 1);
call create_input(8, 10);
call create_input(8, 3);
call create_input(8, 0);
call create_output(8, 15);
call create_output(8, 91);
call create_output(8, 28);
call create_output(8, 66);
call create_output(8, 1);
call create_output(8, 55);
call create_output(8, 6);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 8,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 8,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (8, @instruction_tool_id);

insert into boards set
  id = 9,
  width = 7,
  height = 7;
insert into levels set
  id = 9,
  uuid = uuid(),
  external_id = 'bc27b58a0cafb0ba',
  name = 'Multiplier',
  author_id = null,
  initial_board_id = 9;
call create_description(9, "> Read two positive numbers x and y from the input");
call create_description(9, "> Output x * y");
call create_description(9, "The last input is 0 should not be outputed");
call create_input(9, 12);
call create_input(9, 2);
call create_input(9, 6);
call create_input(9, 6);
call create_input(9, 5);
call create_input(9, 7);
call create_input(9, 1);
call create_input(9, 1);
call create_input(9, 7);
call create_input(9, 11);
call create_input(9, 6);
call create_input(9, 3);
call create_input(9, 0);
call create_output(9, 24);
call create_output(9, 36);
call create_output(9, 35);
call create_output(9, 1);
call create_output(9, 77);
call create_output(9, 18);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 9,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('SendToBottom', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 9,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (9, @instruction_tool_id);

insert into boards set
  id = 10,
  width = 7,
  height = 7;
insert into levels set
  id = 10,
  uuid = uuid(),
  external_id = '9abf854cff37e96b',
  name = 'Divide and conquer',
  author_id = null,
  initial_board_id = 10;
call create_description(10, "> Read two positive numbers x and y from the input");
call create_description(10, "> Output ⌊x / y⌋");
call create_description(10, "The last input is 0 should not be outputed");
call create_input(10, 12);
call create_input(10, 1);
call create_input(10, 8);
call create_input(10, 2);
call create_input(10, 8);
call create_input(10, 8);
call create_input(10, 11);
call create_input(10, 2);
call create_input(10, 5);
call create_input(10, 7);
call create_input(10, 10);
call create_input(10, 4);
call create_input(10, 0);
call create_output(10, 12);
call create_output(10, 4);
call create_output(10, 1);
call create_output(10, 5);
call create_output(10, 0);
call create_output(10, 2);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 10,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction('SendToBottom', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction_push_to_stack(0, @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) 
  values (10, @instruction_tool_id);
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 10,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (10, @instruction_tool_id);

insert into boards set
  id = 11,
  width = 5,
  height = 5;
insert into levels set
  id = 11,
  uuid = uuid(),
  external_id = '407410b1638112a9',
  name = 'Sequence reverser',
  author_id = null,
  initial_board_id = 11;
call create_description(11, "> Read a sequence of numbers from input");
call create_description(11, "> Output the sequence in reverse");
call create_description(11, "The last input is 0 is not part of the sequence");
call create_input(11, -19);
call create_input(11, -2);
call create_input(11, 94);
call create_input(11, -5);
call create_input(11, 19);
call create_input(11, 7);
call create_input(11, 33);
call create_input(11, -92);
call create_input(11, 29);
call create_input(11, -39);
call create_input(11, 0);
call create_output(11, -39);
call create_output(11, 29);
call create_output(11, -92);
call create_output(11, 33);
call create_output(11, 7);
call create_output(11, 19);
call create_output(11, -5);
call create_output(11, 94);
call create_output(11, -2);
call create_output(11, -19);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 11,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 11,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (11, @instruction_tool_id);

insert into boards set
  id = 12,
  width = 7,
  height = 7;
insert into levels set
  id = 12,
  uuid = uuid(),
  external_id = 'b96e6c12476716a3',
  name = 'Sequence sorter',
  author_id = null,
  initial_board_id = 12;
call create_description(12, "> Read a sequence from the input");
call create_description(12, "> Output the sequence sorted from lowest to highest");
call create_description(12, "The last input is 0 should not be outputed");
call create_input(12, 1);
call create_input(12, 4);
call create_input(12, 3);
call create_input(12, 7);
call create_input(12, 11);
call create_input(12, 15);
call create_input(12, 4);
call create_input(12, 14);
call create_input(12, 4);
call create_input(12, 10);
call create_input(12, 8);
call create_input(12, 7);
call create_input(12, 0);
call create_output(12, 1);
call create_output(12, 3);
call create_output(12, 4);
call create_output(12, 4);
call create_output(12, 4);
call create_output(12, 7);
call create_output(12, 7);
call create_output(12, 8);
call create_output(12, 10);
call create_output(12, 11);
call create_output(12, 14);
call create_output(12, 15);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 12,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('SendToBottom', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('CompareLessThan', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 12,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (12, @instruction_tool_id);

insert into boards set
  id = 13,
  width = 8,
  height = 8;
insert into levels set
  id = 13,
  uuid = uuid(),
  external_id = '1fac7ddba473e99d',
  name = 'Less is more',
  author_id = null,
  initial_board_id = 13;
call create_description(13, "> Read two numbers a and b from the input");
call create_description(13, "> If a < b output a, otherwise output b");
call create_description(13, "The last input is 0 is not part of the sequence");
call create_input(13, 6);
call create_input(13, 15);
call create_input(13, 11);
call create_input(13, 3);
call create_input(13, 9);
call create_input(13, 7);
call create_input(13, 15);
call create_input(13, 15);
call create_input(13, 3);
call create_input(13, 7);
call create_input(13, 0);
call create_output(13, 6);
call create_output(13, 3);
call create_output(13, 7);
call create_output(13, 15);
call create_output(13, 3);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 13,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Duplicate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
call create_instruction('Decrement', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
call create_instruction('Swap', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
call create_instruction('Read', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
call create_instruction('PopFromStack', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 13,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('Terminate', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (13, @instruction_tool_id);

insert into boards set
  id = 14,
  width = 5,
  height = 5;
insert into levels set
  id = 14,
  uuid = uuid(),
  external_id = 'be13bbdd076a586c',
  name = 'Labyrinth 1',
  author_id = null,
  initial_board_id = 14;
call create_description(14, "> Terminate the program");
call create_description(14, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (14, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 14,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );

insert into boards set
  id = 15,
  width = 5,
  height = 5;
insert into levels set
  id = 15,
  uuid = uuid(),
  external_id = 'e6d9465e4aacaa0f',
  name = 'Labyrinth 2',
  author_id = null,
  initial_board_id = 15;
call create_description(15, "> Terminate the program");
call create_description(15, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (15, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 15,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );

insert into boards set
  id = 16,
  width = 5,
  height = 5;
insert into levels set
  id = 16,
  uuid = uuid(),
  external_id = 'e81d1f82a8a37103',
  name = 'Labyrinth 3',
  author_id = null,
  initial_board_id = 16;
call create_description(16, "> Terminate the program");
call create_description(16, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (16, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 16,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (16, @instruction_tool_id);

insert into boards set
  id = 17,
  width = 5,
  height = 5;
insert into levels set
  id = 17,
  uuid = uuid(),
  external_id = 'e7d5826a6db19981',
  name = 'Labyrinth 4',
  author_id = null,
  initial_board_id = 17;
call create_description(17, "> Terminate the program");
call create_description(17, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (17, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 17,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (17, @instruction_tool_id);

insert into boards set
  id = 18,
  width = 5,
  height = 5;
insert into levels set
  id = 18,
  uuid = uuid(),
  external_id = '519983570eefe19c',
  name = 'Labyrinth 5',
  author_id = null,
  initial_board_id = 18;
call create_description(18, "> Terminate the program");
call create_description(18, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (18, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 18,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );

insert into boards set
  id = 19,
  width = 5,
  height = 5;
insert into levels set
  id = 19,
  uuid = uuid(),
  external_id = '81101cdad21a4ed2',
  name = 'Labyrinth 6',
  author_id = null,
  initial_board_id = 19;
call create_description(19, "> Terminate the program");
call create_description(19, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (19, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 19,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (19, @instruction_tool_id);

insert into boards set
  id = 20,
  width = 5,
  height = 5;
insert into levels set
  id = 20,
  uuid = uuid(),
  external_id = '36ae04449442c355',
  name = 'Labyrinth 7',
  author_id = null,
  initial_board_id = 20;
call create_description(20, "> Terminate the program");
call create_description(20, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (20, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 20,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
insert into level_instruction_tools set
  level_id = 20,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'BranchAnyDirection'
    limit 1
  );
call create_instruction('JumpForward', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (20, @instruction_tool_id);

insert into boards set
  id = 21,
  width = 5,
  height = 5;
insert into levels set
  id = 21,
  uuid = uuid(),
  external_id = '42cdf083b26bb8ab',
  name = 'Labyrinth 8',
  author_id = null,
  initial_board_id = 21;
call create_description(21, "> Output 1, 2, 3, 4");
call create_description(21, "> Terminate the program");

call create_output(21, 1);
call create_output(21, 2);
call create_output(21, 3);
call create_output(21, 4);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (21, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 21,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );

insert into boards set
  id = 22,
  width = 5,
  height = 5;
insert into levels set
  id = 22,
  uuid = uuid(),
  external_id = '5ed6d025ab5937e4',
  name = 'Labyrinth 9',
  author_id = null,
  initial_board_id = 22;
call create_description(22, "> Terminate the program");
call create_description(22, "> Don't hit any of the exceptions");



call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (22, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 22,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );

insert into boards set
  id = 23,
  width = 5,
  height = 5;
insert into levels set
  id = 23,
  uuid = uuid(),
  external_id = 'b4c862e5dcfb82c1',
  name = 'Labyrinth 10',
  author_id = null,
  initial_board_id = 23;
call create_description(23, "> Output 1");
call create_description(23, "> Terminate the program");
call create_description(23, "> Don't hit any of the exceptions");

call create_output(23, 1);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (23, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 23,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Increment', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (23, @instruction_tool_id);
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (23, @instruction_tool_id);

insert into boards set
  id = 24,
  width = 5,
  height = 5;
insert into levels set
  id = 24,
  uuid = uuid(),
  external_id = 'f8ba39bc9d01ef03',
  name = 'Labyrinth 11',
  author_id = null,
  initial_board_id = 24;
call create_description(24, "> Output 1");
call create_description(24, "> Terminate the program");
call create_description(24, "> Don't hit any of the exceptions");

call create_output(24, 1);

call create_instruction('NoOp', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (24, @instruction_tool_id);
insert into level_instruction_tools set
  level_id = 24,
  instruction_tool_id = (
    select id from instruction_tools 
    where instruction_tool_type = 'ChangeAnyDirection'
    limit 1
  );
call create_instruction('Print', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values 
  (24, @instruction_tool_id);
