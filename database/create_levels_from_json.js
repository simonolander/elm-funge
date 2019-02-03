function to_insert_statement(level_list) {
    return level_list.map((level, index) => {
        const id = index + 1;
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
                )
            ).filter(statement => typeof statement === 'string')
                .join('\n')

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
    }).join('\n\n')
}

const levels = [
    {
        "version": 1,
        "id": "88c653c6c3a5b5e7",
        "name": "One, two, three",
        "description": [
            "> Output the numbers 1, 2, and 3"
        ],
        "io": {
            "input": [],
            "output": [
                1,
                2,
                3
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            },
            {
                "tag": "BranchAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "42fe70779bd30656",
        "name": "Double the fun",
        "description": [
            "> Read a number n from input",
            "> Output n * 2",
            "The last input is 0 and should not be printed"
        ],
        "io": {
            "input": [
                1,
                8,
                19,
                3,
                5,
                31,
                9,
                0
            ],
            "output": [
                2,
                16,
                38,
                6,
                10,
                62,
                18
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Add"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            },
            {
                "tag": "BranchAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "e2f96c5345e5f1f6",
        "name": "Count down",
        "description": [
            "> Read a number n from input",
            "> Output all the numbers from n to 0",
            "The last input is 0 and should not be printed"
        ],
        "io": {
            "input": [
                7,
                3,
                10,
                0
            ],
            "output": [
                7,
                6,
                5,
                4,
                3,
                2,
                1,
                0,
                3,
                2,
                1,
                0,
                10,
                9,
                8,
                7,
                6,
                5,
                4,
                3,
                2,
                1,
                0
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            },
            {
                "tag": "BranchAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "c2003520d988f8d0",
        "name": "Some sums",
        "description": [
            "> Read two numbers a and b from input",
            "> Output a + b",
            "The last input is 0 and should not be printed"
        ],
        "io": {
            "input": [
                1,
                5,
                13,
                10,
                11,
                10,
                8,
                8,
                0
            ],
            "output": [
                6,
                23,
                21,
                16
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "d3c077ea5033222c",
        "name": "Signal amplifier",
        "description": [
            "> Read a number x from the input",
            "> Output x + 10",
            "The last input is 0 should not be outputed"
        ],
        "io": {
            "input": [
                24,
                145,
                49,
                175,
                166,
                94,
                38,
                90,
                165,
                211,
                0
            ],
            "output": [
                34,
                155,
                59,
                185,
                176,
                104,
                48,
                100,
                175,
                221
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "1a3c6d6a80769a07",
        "name": "One minus the other",
        "description": [
            "> Read two numbers a and b from input",
            "> Output a - b",
            "The last input is 0 and should not be printed"
        ],
        "io": {
            "input": [
                18,
                4,
                9,
                17,
                13,
                13,
                12,
                1,
                17,
                3,
                0
            ],
            "output": [
                14,
                -8,
                0,
                11,
                14
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "3ee1f15ae601fc94",
        "name": "Powers of two",
        "description": [
            "> Read a number n from input",
            "> Output 2^n ",
            "The last input is 0 and should not be printed"
        ],
        "io": {
            "input": [
                1,
                4,
                3,
                2,
                5,
                6,
                0
            ],
            "output": [
                2,
                16,
                8,
                4,
                32,
                64
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "24c7efb5c41f8f8f",
        "name": "Triangular numbers",
        "description": [
            "> Read a number n from input",
            "> Output n*(n+1)/2 ",
            "The last input is 0 and should not be printed"
        ],
        "io": {
            "input": [
                5,
                13,
                7,
                11,
                1,
                10,
                3,
                0
            ],
            "output": [
                15,
                91,
                28,
                66,
                1,
                55,
                6
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "bc27b58a0cafb0ba",
        "name": "Multiplier",
        "description": [
            "> Read two positive numbers x and y from the input",
            "> Output x * y",
            "The last input is 0 should not be outputed"
        ],
        "io": {
            "input": [
                12,
                2,
                6,
                6,
                5,
                7,
                1,
                1,
                7,
                11,
                6,
                3,
                0
            ],
            "output": [
                24,
                36,
                35,
                1,
                77,
                18
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "SendToBottom"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "9abf854cff37e96b",
        "name": "Divide and conquer",
        "description": [
            "> Read two positive numbers x and y from the input",
            "> Output ⌊x / y⌋",
            "The last input is 0 should not be outputed"
        ],
        "io": {
            "input": [
                12,
                1,
                8,
                2,
                8,
                8,
                11,
                2,
                5,
                7,
                10,
                4,
                0
            ],
            "output": [
                12,
                4,
                1,
                5,
                0,
                2
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "SendToBottom"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PushToStack",
                    "value": 0
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "407410b1638112a9",
        "name": "Sequence reverser",
        "description": [
            "> Read a sequence of numbers from input",
            "> Output the sequence in reverse",
            "The last input is 0 is not part of the sequence"
        ],
        "io": {
            "input": [
                -19,
                -2,
                94,
                -5,
                19,
                7,
                33,
                -92,
                29,
                -39,
                0
            ],
            "output": [
                -39,
                29,
                -92,
                33,
                7,
                19,
                -5,
                94,
                -2,
                -19
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "b96e6c12476716a3",
        "name": "Sequence sorter",
        "description": [
            "> Read a sequence from the input",
            "> Output the sequence sorted from lowest to highest",
            "The last input is 0 should not be outputed"
        ],
        "io": {
            "input": [
                1,
                4,
                3,
                7,
                11,
                15,
                4,
                14,
                4,
                10,
                8,
                7,
                0
            ],
            "output": [
                1,
                3,
                4,
                4,
                4,
                7,
                7,
                8,
                10,
                11,
                14,
                15
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "SendToBottom"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "CompareLessThan"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "1fac7ddba473e99d",
        "name": "Less is more",
        "description": [
            "> Read two numbers a and b from the input",
            "> If a < b output a, otherwise output b",
            "The last input is 0 is not part of the sequence"
        ],
        "io": {
            "input": [
                6,
                15,
                11,
                3,
                9,
                7,
                15,
                15,
                3,
                7,
                0
            ],
            "output": [
                6,
                3,
                7,
                15,
                3
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Duplicate"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Decrement"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Swap"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Read"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "PopFromStack"
                }
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Terminate"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "be13bbdd076a586c",
        "name": "Labyrinth 1",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Terminate"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "e6d9465e4aacaa0f",
        "name": "Labyrinth 2",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "e81d1f82a8a37103",
        "name": "Labyrinth 3",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "e7d5826a6db19981",
        "name": "Labyrinth 4",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "519983570eefe19c",
        "name": "Labyrinth 5",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "PushToStack",
                        "value": 1
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Branch",
                        "trueDirection": "Right",
                        "falseDirection": "Up"
                    },
                    {
                        "tag": "Terminate"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "81101cdad21a4ed2",
        "name": "Labyrinth 6",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "PushToStack",
                        "value": 1
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Branch",
                        "trueDirection": "Right",
                        "falseDirection": "Up"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "36ae04449442c355",
        "name": "Labyrinth 7",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Increment"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Branch",
                        "trueDirection": "Right",
                        "falseDirection": "Left"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "BranchAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "JumpForward"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "42cdf083b26bb8ab",
        "name": "Labyrinth 8",
        "description": [
            "> Output 1, 2, 3, 4",
            "> Terminate the program"
        ],
        "io": {
            "input": [],
            "output": [
                1,
                2,
                3,
                4
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Terminate"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Increment"
                    },
                    {
                        "tag": "Print"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Print"
                    },
                    {
                        "tag": "Increment"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "5ed6d025ab5937e4",
        "name": "Labyrinth 9",
        "description": [
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": []
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "JumpForward"
                    }
                ],
                [
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            }
        ]
    },
    {
        "version": 1,
        "id": "b4c862e5dcfb82c1",
        "name": "Labyrinth 10",
        "description": [
            "> Output 1",
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": [
                1
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    }
                ],
                [
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "Branch",
                        "trueDirection": "Left",
                        "falseDirection": "Up"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "Branch",
                        "trueDirection": "Right",
                        "falseDirection": "Up"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Increment"
                }
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            }
        ]
    },
    {
        "version": 1,
        "id": "f8ba39bc9d01ef03",
        "name": "Labyrinth 11",
        "description": [
            "> Output 1",
            "> Terminate the program",
            "> Don't hit any of the exceptions"
        ],
        "io": {
            "input": [],
            "output": [
                1
            ]
        },
        "initialBoard": {
            "version": 1,
            "board": [
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    }
                ],
                [
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Branch",
                        "trueDirection": "Up",
                        "falseDirection": "Right"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "Terminate"
                    },
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    }
                ],
                [
                    {
                        "tag": "Exception",
                        "exceptionMessage": "Don't hit the exceptions"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "Branch",
                        "trueDirection": "Down",
                        "falseDirection": "Right"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    }
                ],
                [
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "JumpForward"
                    },
                    {
                        "tag": "Increment"
                    },
                    {
                        "tag": "NoOp"
                    },
                    {
                        "tag": "NoOp"
                    }
                ]
            ]
        },
        "instructionTools": [
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "NoOp"
                }
            },
            {
                "tag": "ChangeAnyDirection"
            },
            {
                "tag": "JustInstruction",
                "instruction": {
                    "tag": "Print"
                }
            }
        ]
    }
];

console.log(to_insert_statement(levels));