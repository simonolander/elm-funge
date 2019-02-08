
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