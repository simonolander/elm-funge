create table directions (
    direction varchar(255) primary key not null
);

insert into directions values 
    ('Left'),
    ('Up'),
    ('Right'),
    ('Down');

create table instruction_types (
    instruction_type varchar(255) primary key not null
);

insert into instruction_types values 
    ('NoOp'),
    ('ChangeDirection'),
    ('PushToStack'),
    ('PopFromStack'),
    ('JumpForward'),
    ('Duplicate'),
    ('Swap'),
    ('Negate'),
    ('Abs'),
    ('Not'),
    ('Increment'),
    ('Decrement'),
    ('Add'),
    ('Subtract'),
    ('Multiply'),
    ('Divide'),
    ('Equals'),
    ('CompareLessThan'),
    ('And'),
    ('Or'),
    ('XOr'),
    ('Read'),
    ('Print'),
    ('Branch'),
    ('Terminate'),
    ('SendToBottom'),
    ('Exception');

create table instructions (
    id serial primary key,
    instruction_type varchar(255) not null,
    foreign key (instruction_type) references instruction_types(instruction_type)
);

create table instructions_change_direction (
    id serial primary key,
    instruction_id bigint unsigned not null unique,
    direction varchar(255) not null unique,
    foreign key (instruction_id) references instructions(id),
    foreign key (direction) references directions(direction)
);

insert into instructions (id, instruction_type) values
    (1, 'ChangeDirection'),
    (2, 'ChangeDirection'),
    (3, 'ChangeDirection'),
    (4, 'ChangeDirection');

insert into instructions_change_direction (id, instruction_id, direction) values 
    (1, 1, 'Left'),
    (2, 2, 'Up'),
    (3, 3, 'Right'),
    (4, 4, 'Down');

create table instructions_branch (
    id serial primary key,
    instruction_id bigint unsigned not null unique,
    true_direction varchar(255) not null,
    false_direction varchar(255) not null,
    unique (true_direction, false_direction),
    foreign key (instruction_id) references instructions(id),
    foreign key (true_direction) references directions(direction),
    foreign key (false_direction) references directions(direction)
);

insert into instructions (id, instruction_type) values 
    (5, 'Branch'),
    (6, 'Branch'),
    (7, 'Branch'),
    (8, 'Branch'),
    (9, 'Branch'),
    (10, 'Branch'),
    (11, 'Branch'),
    (12, 'Branch'),
    (13, 'Branch'),
    (14, 'Branch'),
    (15, 'Branch'),
    (16, 'Branch'),
    (17, 'Branch'),
    (18, 'Branch'),
    (19, 'Branch'),
    (20, 'Branch');

insert into instructions_branch (id, instruction_id, true_direction, false_direction) values
    (1, 5, 'Left', 'Left'),
    (2, 6, 'Left', 'Up'),
    (3, 7, 'Left', 'Right'),
    (4, 8, 'Left', 'Down'),
    (5, 9, 'Up', 'Left'),
    (6, 10, 'Up', 'Up'),
    (7, 11, 'Up', 'Right'),
    (8, 12, 'Up', 'Down'),
    (9, 13, 'Right', 'Left'),
    (10, 14, 'Right', 'Up'),
    (11, 15, 'Right', 'Right'),
    (12, 16, 'Right', 'Down'),
    (13, 17, 'Down', 'Left'),
    (14, 18, 'Down', 'Up'),
    (15, 19, 'Down', 'Right'),
    (16, 20, 'Down', 'Down');

create table instructions_exception (
    id serial primary key,
    instruction_id bigint unsigned not null unique,
    message varchar(255) not null unique,
    created_time datetime not null default current_timestamp(),
    modified_time datetime on update current_timestamp(),
    foreign key (instruction_id) references instructions(id)
);

create table instructions_push_to_stack (
    id serial primary key,
    instruction_id bigint unsigned not null unique,
    value int not null unique,
    foreign key (instruction_id) references instructions(id)
);

create table instruction_tool_types (
    instruction_tool_type varchar(255) primary key not null
);

insert into instruction_tool_types values
    ('JustInstruction'),
    ('ChangeAnyDirection'),
    ('BranchAnyDirection'),
    ('PushValueToStack');

create table instruction_tools (
    id serial primary key,
    instruction_tool_type varchar(255) not null,
    foreign key (instruction_tool_type) references instruction_tool_types(instruction_tool_type)
);

create table instruction_tools_just_instruction (
    id serial primary key,
    instruction_tool_id bigint unsigned not null unique,
    instruction_id bigint unsigned not null unique,
    foreign key (instruction_tool_id) references instruction_tools(id),
    foreign key (instruction_id) references instructions(id)
);

create table boards (
    id serial primary key,
    width int unsigned not null,
    height int unsigned not null,
    created_time datetime not null default current_timestamp(),
    modified_time datetime on update current_timestamp()
);

create table board_instructions (
    id serial primary key,
    board_id bigint unsigned not null,
    instruction_id bigint unsigned not null,
    x int unsigned not null,
    y int unsigned not null,
    unique (board_id, x, y),
    foreign key (board_id) references boards(id),
    foreign key (instruction_id) references instructions(id)
);

create table users (
    id serial primary key,
    username varchar(255) not null unique,
    created_time datetime not null default current_timestamp(),
    modified_time datetime on update current_timestamp()
);

create table levels (
    id serial primary key,
    uuid char(36) not null unique,
    author_id bigint unsigned default null,
    external_id varchar(255) not null unique,
    name varchar(255) not null,
    initial_board_id bigint unsigned not null,
    created_time datetime not null default current_timestamp(),
    modified_time datetime on update current_timestamp(),
    foreign key (author_id) references users(id),
    foreign key (initial_board_id) references boards(id)
);

create table level_descriptions (
    id serial primary key,
    level_id bigint unsigned not null,
    ordinal int unsigned not null,
    description text not null,
    unique (level_id, ordinal),
    foreign key (level_id) references levels(id)
);

create table level_inputs (
    id serial primary key,
    level_id bigint unsigned not null,
    ordinal int unsigned not null,
    value int not null,
    unique (level_id, ordinal),
    foreign key (level_id) references levels(id)
);

create table level_outputs (
    id serial primary key,
    level_id bigint unsigned not null,
    ordinal int unsigned not null,
    value int not null,
    unique (level_id, ordinal),
    foreign key (level_id) references levels(id)
);

create table level_instruction_tools (
    id serial primary key,
    level_id bigint unsigned not null,
    instruction_tool_id bigint unsigned not null,
    unique (level_id, instruction_tool_id),
    foreign key (instruction_tool_id) references instruction_tools(id),
    foreign key (level_id) references levels(id)
);

create table level_solutions (
    id serial primary key,
    level_id bigint unsigned not null,
    board_id bigint unsigned not null,
    solver_id bigint unsigned not null,
    number_of_steps int unsigned not null,
    number_of_instructions int unsigned not null,
    area int unsigned not null,
    created_time datetime not null default current_timestamp(),
    modified_time datetime on update current_timestamp(),
    unique (level_id, board_id, solver_id),
    foreign key (level_id) references levels(id),
    foreign key (board_id) references boards(id),
    foreign key (solver_id) references users(id)
);