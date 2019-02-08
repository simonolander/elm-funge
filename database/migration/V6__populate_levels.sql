
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


call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 3,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 3,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 4,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 1,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 0,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 16,
  instruction_id = @instruction_id,
  x = 2,
  y = 4;
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


call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 1,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 3,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 1,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 2,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 4,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 0,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 1,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 2,
  y = 3;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 3,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 3,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 17,
  instruction_id = @instruction_id,
  x = 4,
  y = 4;
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


call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 0,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 2,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 3,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 4,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction_push_to_stack(1, @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 4,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 2,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 4,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 0,
  y = 4;
insert into board_instructions set
  board_id = 18,
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = 'Right'
        and false_direction = 'Up'
      limit 1
  ),
  x = 3,
  y = 4;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 18,
  instruction_id = @instruction_id,
  x = 4,
  y = 4;
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



call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 2,
  y = 1;
call create_instruction_push_to_stack(1, @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 3,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 2,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 4,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
insert into board_instructions set
  board_id = 19,
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = 'Right'
        and false_direction = 'Up'
      limit 1
  ),
  x = 2,
  y = 3;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 3,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 4,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 0,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 1,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 2,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 3,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 19,
  instruction_id = @instruction_id,
  x = 4,
  y = 4;
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


call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 3,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 4,
  y = 0;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 0,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 1,
  y = 1;
call create_instruction('Increment', @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 3,
  y = 1;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 3,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 4,
  y = 2;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 0,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 1,
  y = 3;
insert into board_instructions set
  board_id = 20,
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = 'Right'
        and false_direction = 'Left'
      limit 1
  ),
  x = 2,
  y = 3;
call create_instruction('Terminate', @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 3,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 4,
  y = 3;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 1,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 2,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 3,
  y = 4;
call create_instruction_exception("Don't hit the exceptions", @instruction_id);
insert into board_instructions set
  board_id = 20,
  instruction_id = @instruction_id,
  x = 4,
  y = 4;
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

