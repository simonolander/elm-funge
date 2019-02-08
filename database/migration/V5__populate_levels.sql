
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


call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 2,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 1,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 2,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 1,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 3,
  y = 4;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 14,
  instruction_id = @instruction_id,
  x = 4,
  y = 4;
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


call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 15,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 15,
  instruction_id = @instruction_id,
  x = 3,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 15,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 15,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 15,
  instruction_id = @instruction_id,
  x = 1,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 15,
  instruction_id = @instruction_id,
  x = 0,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 15,
  instruction_id = @instruction_id,
  x = 4,
  y = 4;
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
