const levels = require('./levels').levels

function to_insert_statement(level, id) {
    const board_height = level.initialBoard.board.length;
    const board_width = level.initialBoard.board[0].length;
    const board_statement =
        `insert into boards set
  id = ${id},
  width = ${board_width},
  height = ${board_height};`
    const level_statement =
        `insert into levels set
  id = ${id},
  uuid = uuid(),
  external_id = '${level.id}',
  name = '${level.name}',
  author_id = null,
  initial_board_id = ${id};`
    const descriptions_statement =
        level.description.map(
            description => `call create_description(${id}, "${description}");`
        ).join("\n");

    const input_statement =
        level.io.input.map(
            value => `call create_input(${id}, ${value});`
        ).join("\n");

    const output_statement =
        level.io.output.map(
            value => `call create_output(${id}, ${value});`
        ).join("\n");

    const initial_board_instructions_statement =
        level.initialBoard.board.map(
            (row, row_index) => row.map(
                (instruction, column_index) => {
                    switch (instruction.tag) {
                        case 'NoOp':
                            return null;
                        case 'Exception':
                            return `call create_instruction_exception("${instruction.exceptionMessage}", @instruction_id);
insert into board_instructions set
  board_id = ${id},
  instruction_id = @instruction_id,
  x = ${column_index},
  y = ${row_index};`
                        case 'PushToStack':
                            return `call create_instruction_push_to_stack(${instruction.value}, @instruction_id);
insert into board_instructions set
  board_id = ${id},
  instruction_id = @instruction_id,
  x = ${column_index},
  y = ${row_index};`
                        case 'Branch':
                            return `insert into board_instructions set
  board_id = ${id},
  instruction_id = (
    select instruction_id from instructions_branch
      where true_direction = '${instruction.trueDirection}'
        and false_direction = '${instruction.falseDirection}'
      limit 1
  ),
  x = ${column_index},
  y = ${row_index};`;
                        case 'ChangeDirection':
                            return `insert into board_instructions set
  board_id = ${id},
  instruction_id = (
    select instruction_id from instructions_change_direction
      where direction = '${instruction.direction}'
      limit 1
  ),
  x = ${column_index},
  y = ${row_index};`;
                        default:
                            return `call create_instruction('${instruction.tag}', @instruction_id);
insert into board_instructions set
  board_id = ${id},
  instruction_id = @instruction_id,
  x = ${column_index},
  y = ${row_index};`
                    }
                }
            ).filter(statement => typeof statement === 'string')
                .join('\n')
        ).join('\n')

    const instruction_tool_statement =
        level.instructionTools.map(
            instructionTool => {
                switch (instructionTool.tag) {
                    case 'JustInstruction':
                        switch (instructionTool.instruction.tag) {
                            case 'Exception':
                                return `call create_instruction_exception("${instructionTool.instruction.exceptionMessage}", @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id)
  values (${id}, @instruction_tool_id);`
                            case 'PushToStack':
                                return `call create_instruction_push_to_stack(${instructionTool.instruction.value}, @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id)
  values (${id}, @instruction_tool_id);`
                            case 'Branch':
                                return `insert into board_instructions set
  board_id = ${id},
  instruction_id = (
  select instruction_id from instructions_branch
    where true_direction = '${instructionTool.instruction.trueDirection}'
    and false_direction = '${instructionTool.instruction.falseDirection}'
    limit 1
  ),
  x = ${column_index},
  y = ${row_index};`;
                            case 'ChangeDirection':
                                return `insert into board_instructions set
  board_id = ${id},
  instruction_id = (
  select instruction_id from instructions_change_direction
    where direction = '${instructionTool.instruction.direction}'
    limit 1
  ),
  x = ${column_index},
  y = ${row_index};`;
                            default:
                                return `call create_instruction('${instructionTool.instruction.tag}', @instruction_id);
call create_instruction_tool_just_instruction(@instruction_id, @instruction_tool_id);
insert into level_instruction_tools (level_id, instruction_tool_id) values
  (${id}, @instruction_tool_id);`
                        }
                    default:
                        return `insert into level_instruction_tools set
  level_id = ${id},
  instruction_tool_id = (
    select id from instruction_tools
    where instruction_tool_type = '${instructionTool.tag}'
    limit 1
  );`
                }
            }
        ).join('\n')
    statement = [
        board_statement,
        level_statement,
        descriptions_statement,
        input_statement,
        output_statement,
        initial_board_instructions_statement,
        instruction_tool_statement,
    ].join('\n')
    return statement
}

function to_insert_statement_list(level_list) {
    return level_list.map((level, index) => to_insert_statement(level, index + 1))
        .join('\n\n')
}

function toJson(levels) {
    return levels.map(level => ({
        ...level,
        version: 2,
        initialBoard: {
            version: 2,
            width: level.initialBoard.board[0].length,
            height: level.initialBoard.board.length,
            instructions: [].concat(...level.initialBoard.board.map(
                (row, rowIndex) =>
                    row.filter(instruction => instruction.tag !== "NoOp")
                        .map(
                            (instruction, columnIndex) => ({
                                instruction,
                                x: columnIndex,
                                y: rowIndex,
                            })))),
        }
    }))
}

console.log(JSON.stringify(toJson(levels), null, 2));
// console.log(to_insert_statement(levels));