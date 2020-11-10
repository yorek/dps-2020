create schema [web];
go

create user [todo-backend] with password = 'Super_Str0ng*P@ZZword!'
go

alter role [db_datareader] add member [todo-backend];
go

grant execute on schema::[web] to [todo-backend]
go

create sequence dbo.[global_sequence]
as int
start with 1
increment by 1;
go

drop table if exists dbo.todo;
go

create table dbo.todo
(
	[id] int not null primary key default (next value for [global_sequence]),
	[title] nvarchar(100) not null,
	[completed] bit not null default (0)
)
go

/*
	GET
	Accepted Input: 
	''
	'[{"id":1}, {"id":2}]'
*/
create or alter procedure [web].[get_todo]
@payload nvarchar(max) = null
as
begin
	-- return all
	if (@payload = '' or @payload is null) begin;
	select 
		cast(
			(select
				[id],
				[title],
				[completed]
			from
				dbo.todo t
			for json path)
		as nvarchar(max)) as result;
		return;
	end;

	-- return the specified todos
	if (isjson(@payload) <> 1) begin;
		throw 50000, 'Payload is not a valid JSON document', 16;
	end;

	select 
		cast(
			(select
				[id],
				[title],
				[completed]
			from
				dbo.todo t
			where
				exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id)
			for json path)
		as nvarchar(max)) as result
end;
go

/*
	POST
	Accepted Input: 
	'[{"title":"todo title", "completed": 0}, {"title": "another todo"}]'
*/
create or alter procedure [web].[post_todo]
@payload nvarchar(max)
as
begin
	if (isjson(@payload) != 1) begin;
		throw 50000, 'Payload is not a valid JSON document', 16;
	end;

	declare @ids table (id int not null);

	insert into dbo.todo ([title], [completed])
	output inserted.id into @ids
	select [title], isnull([completed],0) from openjson(@payload) with
	(
		[title] nvarchar(100),
		[completed] bit
	)

	declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
	exec [web].[get_todo] @newPayload;
end
go


/*
	PATCH
	Accepted Input: 
	'[{"id":1, "todo":{"id": 10, "title": "updated title", "completed": 1 },{...}]'
*/
create or alter procedure [web].[patch_todo]
@payload nvarchar(max)
as
begin
	if (isjson(@payload) <> 1) begin;
		throw 50000, 'Payload is not a valid JSON document', 16;
	end;

	declare @ids table (id int not null);

	with cte as
	(
		select 
			id,
			new_id,
			title,
			completed
		from 
			openjson(@payload) with
			(
				id int '$.id',
				todo nvarchar(max) as json
			) 
			cross apply openjson(todo) with 
			(
				new_id int '$.id',
				title nvarchar(100),
				completed bit
			)
	)
	update
		t
	set
		[id] = coalesce(c.new_id, t.id),
		[title] = coalesce(c.title, t.title),
		[completed] = coalesce(c.completed, t.completed)
	output 
		inserted.id into @ids
	from
		dbo.[todo] t
	inner join
		cte c on t.id = c.id
	;

	declare @newPayload as nvarchar(max) = (select id from @ids for json auto);
	exec [web].[get_todo] @newPayload;
end
go

/*
	DELETE
	Accepted Input: 
	'[{"id":1}, {"id":2}]'
*/
create or alter procedure [web].[delete_todo]
@payload nvarchar(max) = null
as
begin
	-- delete all
	if (@payload = '' or @payload is null) begin;
		delete from dbo.[todo];
		return;
	end

	-- return the specified todos
	if (isjson(@payload) <> 1) begin;
		throw 50000, 'Payload is not a valid JSON document', 16;
	end;

	delete t from dbo.todo t 
	where exists (select p.id from openjson(@payload) with (id int) as p where p.id = t.id);
end
