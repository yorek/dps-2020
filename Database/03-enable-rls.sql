drop security policy if exists rls.todo_access_policy;
drop function if exists rls.fn_security_predicate;
drop table if exists rls.todo_permissions
go

drop schema if exists rls;
go
create schema rls;
go

create table rls.todo_permissions
(
    user_hash_id bigint not null,
    todo_id int not null foreign key references dbo.[todo](id),
    can_access bit not null default(0),
    constraint pk__web_todo_permissions primary key nonclustered (todo_id, user_hash_id)
)
go

/*
    Create Security Predicate Function

    Note: 
    Remove the comments if you want to make sure that only authorized users, accessing via the backend API, 
    will be able to see the stored todos, and allow any db_owner to always see anything,
    even if RLS is enabled
*/
create or alter function rls.fn_security_predicate(@todo_id int)  
returns table
with schemabinding
as
return
select 
    can_access
from
    rls.todo_permissions
where
	(
--		database_principal_id() = database_principal_id('todo-backend')
--	and     
		[user_hash_id] = cast(session_context(N'user-hash-id') as bigint)
	and
		[todo_id] = @todo_id
	)
--or	
--	is_member('db_owner') = 1
go

/*
    Create the Security Policy but keep it *disabled*
*/
create security policy rls.todo_access_policy
add filter predicate rls.fn_security_predicate(id) on dbo.[todo]
with (state = off);  
go