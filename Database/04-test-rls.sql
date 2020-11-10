/*
	Cleanup database
*/
delete from [rls].[todo_permissions];
delete from [dbo].[todo];

/*
	Insert sample todos
*/
insert into dbo.todo values
(1, 'Todo 1', 0, 1),
(2, 'Todo 2', 0, 2)
go

/*
	Everything is visible
*/
select * from dbo.[todo]
go

/*
	Enable Security Policy
*/
alter security policy rls.todo_access_policy
with (state = on);  
go

/*
	As even the admin can't see anything
*/
select * from dbo.[todo]
go

/*
	Allow user with user-hash-id 12345 to access ToDo witih Id=1
*/
insert into rls.[todo_permissions] values (12345, 1, 1)
go

/*
	Nothing yet....
*/
select * from dbo.[todo]
go

/*
	Add the user-hash-id into the session context,
	as it is needed by the Policy Function to correctly
	allow a user to access its todo
*/

exec sys.sp_set_session_context @key=N'user-hash-id', @value=12345, @read_only=0;
go

/*
	ToDo with Id=1 now visible
*/
select * from dbo.[todo]
go

/*
	Access the key-value pair saved in the context
*/
select session_context(N'user-hash-id')
go

/*
	Check if Row Level Security is enabled or not on the table
*/
select 
	po.[name] as policy_name,
	pr.[predicate_definition],
	object_name(pr.[target_object_id]) as table_name,
	po.[is_enabled]
from 
	sys.[security_policies] po inner join sys.[security_predicates] pr on po.[object_id] = pr.[object_id]

