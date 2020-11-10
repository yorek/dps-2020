# Data Platform Summit 2020 
# Create secure API with .NET, Dapper and Azure SQL

Demo used in the "Data Platform Summit 2020" for the session "Create secure API with .NET, Dapper and Azure SQL".

## Pre-requisites

Make sure you have an Azure SQL database to use for this demo. If you need help to create an Azure SQL database, take a look here: [Running the samples](https://github.com/yorek/azure-sql-db-samples#running-the-samples)

You will also need Visual Studio Code or Visual Studio 2019 and .NET Core SDK 3.1 

## Iteration 1 - Create ToDo Backend API

In this first step, you will create a fully functioning [backend REST API](http://www.todobackend.com/) for the [ToDo MVC](http://todomvc.com/) Project. The REST API to be created are defined via a series of automated test as described here:

[Creating a new Todo-Backend API implementation](http://www.todobackend.com/contribute.html)

the test can be download and executed locally using a local server, like [Visual Studio Code Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)

[https://github.com/TodoBackend/todo-backend-js-spec]

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

TDB

