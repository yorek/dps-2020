# Data Platform Summit 2020 Demos

![License](https://img.shields.io/badge/license-MIT-green.svg)

Demo used in the "Data Platform Summit 2020" for the session 

**Create secure API with .NET, Dapper and Azure SQL**

## Pre-requisites

Make sure you have an Azure SQL database to use for this demo. If you need help to create an Azure SQL database, take a look here: [Running the samples](https://github.com/yorek/azure-sql-db-samples#running-the-samples)

You will also need Visual Studio Code or Visual Studio 2019 and .NET Core SDK 3.1 

## Iteration 1 - Create ToDo Backend API

In this first step, you will create a fully functioning [backend REST API](http://www.todobackend.com/) for the [ToDo MVC](http://todomvc.com/) Project. The REST API to be created are defined via a series of automated test as described here:

[Creating a new Todo-Backend API implementation](http://www.todobackend.com/contribute.html)

the test can be download and executed locally using a local server, like [Visual Studio Code Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer):

[Executable Specs in JavaScript for the Todo-Backend API](https://github.com/TodoBackend/todo-backend-js-spec)

To run the backend API locally, configure the `appsettings.json` to include connection string to the Azure SQL database you want to use for the demo:

```json
"ConnectionStrings": {
    "AzureSQL": "SERVER=<myserver>.database.windows.net;DATABASE=<mydatabase>;UID=todo-backend;PWD=Super_Str0ng*P@ZZword!;"
}
```

make also sure to have created all the needed objects and user, by executing the script `./Database/01-create-objects.sql` in your Azure SQL database. Then, you can just run

```
dotnet run
```

to start the backend and test it using the aforementioned test or a REST tool like [Insomnia](https://insomnia.rest/) to send HTTP requests. For example you can create a new Todo by sending a POST request with 

```json
{
	"title": "my todo"
}
```

as body to `http://localhost:5000/todo` endpoint.

If you try to run the ToDo Backend REST Endpoint test (for example: `http://localhost:5500/index.html?http://localhost:5000/todo`) all tests should be greem with the exception of the test under "tracking todo order" section.

## Iteration 2 - Add support to a new property

We now want to support also the ability to set an order or priority for the ToDo we have. We just have to add a new column to the table and update the related stored procedures. As we didn't use a POCO object and just relied on JSON, there will be no changes needed on the .NET code.

Simply run the `./Database/02-add-order.sql` script in the Azure SQL database used for the sample.

Now re-run the test. Every test should be passing now.

Congratulations, you just extended your schema so that it can now store the `order` field.

IF you want to see other options to manage schema dynamically, maybe that doesn't even require altering the table and updating the stored procedures, take a look here:

[Cloud Day 2020 Demos - Serverless Scalable Back-End API with Hybrid Data Models](https://github.com/yorek/cloud-day-2020)

## Iteration 3 - Add security

It's now time to add security to make sure only authorized user will be able to access to Todo items. First of all you need to setup and enable [Row-Level Security](https://docs.microsoft.com/en-us/sql/relational-databases/security/row-level-security), via the `./Database/enable-rls.sql` script. 

After the script has been executed, RLS will be configured but still in *disabled* state.

Let's now execute the `./Database/04-test-rls.sql` up to the [line 26](https://github.com/yorek/dps-2020/blob/main/Database/04-test-rls.sql#L26) so that RLS will be enabled thanks to the

```sql
alter security policy rls.todo_access_policy
with (state = on);  
```

statement. The script will also wipe clean all the todo, and create just a couple of sample todo, useful for testing RLS. 
 
If you try now to get all todos via the GET HTTP request, you'll get an empty array. You don't have yet any authorization to see anything, so RLS is preventing you to access any existing Todo.

### Creating a JTW token

You need to pass the REST Endpoint a JWT token with details on who you are. The sample contains a `authorization` endpoint that simulates an endpoint that will authenticate the user and will return a valid JWT token, containing the User Hash Id that can be used to allow the authenticated user to access a specific Todo.

In order to simulate authentication, you can POST a Login and Password, for example:

```json
{
    "login": "john.doe@contoso.com",
    "password": "anything-here"
}
```

to http://localhost:5000/authorization. You can pass any login or password, as the sample authorization will always return a JWT token containing the User Hash ID "12345". You can see the content of the JWT token via [jwt.io](https://jwt.io/)

You now have to update the REST API sample so that it will be able to use that token. Make sure you uncomment the [line 74](https://github.com/yorek/dps-2020/blob/main/Startup.cs#L74) in `Startup.cs`:

```csharp
app.UseAuthentication();
```

to allow a user to be authenticated and thus then authorized, and also uncomment the `Authorize` attribute at [line 32](https://github.com/yorek/dps-2020/blob/main/Controllers/ToDoController.cs#L32) of `./Controllers/ToDoController.cs` and [line 52)(https://github.com/yorek/dps-2020/blob/main/Controllers/ToDoController.cs#L52) in the same file to pass to Azure SQL database the Session Context with the User Hash Id available in the JWT token:

```csharp
await conn.ExecuteAsync("sys.sp_set_session_context", new { @key = "user-hash-id", @value = userHashId, @read_only = 1 }, commandType: CommandType.StoredProcedure );
```

You now have to allow user with Hash Id 12345 to be able to access a Todo. For example, to allow access to ToDo 1:

```sql
insert into rls.[todo_permissions] 
    (user_hash_id, todo_id, can_access)
values 
    (12345, 1, 1)
```

You can now run the backend API again and if you try to GET the list of todo, only the authorized todo will be available. Make sure to authenticated your REST calls by [passing the generated JWT token](https://support.insomnia.rest/article/38-authentication) as the [Bearer Token](https://stackoverflow.com/questions/25838183/what-is-the-oauth-2-0-bearer-token-exactly).

Done, your GET endpoint is now secured.

I'll leave it to you to move forward and secure all the other endpoint for POST, DELETE and PATCH, as the approach is very similar to what has been done already for the GET one.

Have fun!
