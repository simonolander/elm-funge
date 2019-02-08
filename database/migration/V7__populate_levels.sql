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
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 21,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction('Increment', @instruction_id);
insert into board_instructions set
  board_id = 21,
  instruction_id = @instruction_id,
  x = 2,
  y = 1;
call create_instruction('Print', @instruction_id);
insert into board_instructions set
  board_id = 21,
  instruction_id = @instruction_id,
  x = 3,
  y = 1;
call create_instruction('Print', @instruction_id);
insert into board_instructions set
  board_id = 21,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction('Increment', @instruction_id);
insert into board_instructions set
  board_id = 21,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;


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


call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 3,
  y = 0;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 0,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 2,
  y = 1;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 1,
  y = 2;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 4,
  y = 3;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 1,
  y = 4;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 2,
  y = 4;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 22,
  instruction_id = @instruction_id,
  x = 3,
  y = 4;
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
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 1,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 3,
  y = 0;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 2,
  y = 1;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 4,
  y = 1;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 0,
  y = 2;
insert into board_instructions set
  board_id = 23,
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = 'Left'
        and false_direction = 'Up'
      limit 1
  ),
  x = 1,
  y = 2;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
insert into board_instructions set
  board_id = 23,
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = 'Right'
        and false_direction = 'Up'
      limit 1
  ),
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 2,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 3,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 0,
  y = 4;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 23,
  instruction_id = @instruction_id,
  x = 3,
  y = 4;
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
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 2,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 3,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 0,
  y = 1;
insert into board_instructions set
  board_id = 24,
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = 'Up'
        and false_direction = 'Right'
      limit 1
  ),
  x = 2,
  y = 1;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 1,
  y = 2;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
insert into board_instructions set
  board_id = 24,
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = 'Down'
        and false_direction = 'Right'
      limit 1
  ),
  x = 2,
  y = 3;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 4,
  y = 3;
call create_instruction('JumpForward', @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 1,
  y = 4;
call create_instruction('Increment', @instruction_id);
insert into board_instructions set
  board_id = 24,
  instruction_id = @instruction_id,
  x = 2,
  y = 4;
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
