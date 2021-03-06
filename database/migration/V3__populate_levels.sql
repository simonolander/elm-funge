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
