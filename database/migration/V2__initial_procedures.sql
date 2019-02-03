delimiter //

create procedure create_description(in level_id bigint, in description text)
begin
    prepare stmt from 'insert into level_descriptions (level_id, ordinal, description) values (?, ?, ?)';
    set @level_id = level_id;
    set @ordinal = (
        select 
            ifnull(max(ordinal) + 1, 0) 
            from level_descriptions
            where level_id = level_id
        );
    set @description = description;
    execute stmt 
        using @level_id, @ordinal, @description;
    deallocate prepare stmt;
end //

create procedure create_input(in level_id bigint, in value int)
begin
    prepare stmt from 'insert into level_inputs (level_id, ordinal, value) values (?, ?, ?)';
    set @level_id = level_id;
    set @ordinal = (
        select 
            ifnull(max(ordinal) + 1, 0) 
            from level_inputs
            where level_id = level_id
        );
    set @value = value;
    execute stmt 
        using @level_id, @ordinal, @value;
    deallocate prepare stmt;
end //

create procedure create_output(in level_id bigint, in value int)
begin
    prepare stmt from 'insert into level_outputs (level_id, ordinal, value) values (?, ?, ?)';
    set @level_id = level_id;
    set @ordinal = (
        select 
            ifnull(max(ordinal) + 1, 0) 
            from level_outputs
            where level_id = level_id
        );
    set @value = value;
    execute stmt 
        using @level_id, @ordinal, @value;
    deallocate prepare stmt;
end //

create procedure create_instruction(in instruction_type varchar(255), out instruction_id bigint)
begin
    set @instruction_type = instruction_type;
    set @existing_instruction_id = null;
    prepare select_stmt from 'select id from instructions where instruction_type = ? limit 1 into @existing_instruction_id';
    execute select_stmt 
        using @instruction_type;
    if @existing_instruction_id is null
    then 
        prepare insert_stmt from 'insert into instructions set instruction_type = ?';
        execute insert_stmt
            using @instruction_type;
        set @existing_instruction_id = last_insert_id();
        deallocate prepare insert_stmt;
    end if;
    set instruction_id = @existing_instruction_id;
    deallocate prepare select_stmt;
end //

create procedure create_instruction_exception(in exception_message varchar(255), out instruction_id bigint)
begin
    prepare select_stmt from 'select instruction_id from instructions_exception where message = ? into @existing_instruction_id';
    set @message = exception_message;
    set @existing_instruction_id = null;
    execute select_stmt 
        using @message;
    if @existing_instruction_id is null
    then 
        insert into instructions set instruction_type = 'Exception';
        set @existing_instruction_id = last_insert_id();
        prepare insert_stmt from 'insert into instructions_exception (instruction_id, message) values (?, ?)';
        execute insert_stmt
            using @existing_instruction_id, @message;
        deallocate prepare insert_stmt;
    end if;
    set instruction_id = @existing_instruction_id;
    deallocate prepare select_stmt;
end //

delimiter ;
