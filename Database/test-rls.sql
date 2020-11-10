delete from [rls].[todo_permissions];
delete from dbo.[todo];


insert into dbo.todo values
(1, 'Todo 1', 0, 1),
(2, 'Todo 2', 0, 2)
go

select * from dbo.[todo]
go


alter security policy rls.todo_access_policy
with (state = on);  
go

select * from dbo.[todo]
go

alter security policy rls.todo_access_policy
with (state = off);  
go

select * from [rls].[todo_permissions]
go

insert into rls.[todo_permissions] values (12345, 1, 1)
go

alter security policy rls.todo_access_policy
with (state = on);  
go

select * from dbo.[todo]
go

exec sys.sp_set_session_context @key=N'user-hash-id', @value=12345, @read_only=0;
go

select * from dbo.[todo]
go

select session_context(N'user-hash-id')
go

select 
	po.[name] as policy_name,
	pr.[predicate_definition],
	object_name(pr.[target_object_id]) as table_name,
	po.[is_enabled]
from 
	sys.[security_policies] po inner join sys.[security_predicates] pr on po.[object_id] = pr.[object_id]

