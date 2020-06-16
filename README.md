# A Salesforce Apex Unit Test Framework for Agile Teams (UPDATED AND REFACTORED!)
## Notices
### (8 to 15th June 2020) Major refactor :) 
As Salesforce moves to a Package based delivery model, this framework needed to be extendable from external packages. You can package this code (or deploy as is), and write your own Objects in your own package (or namespace) without needing to open or edit this code any longer.


In previous versions you would add a new class, and then update the c_TestFactory class to register it as an Entity in an enum before you could generate data from it using the factory. This dependency has been removed.


When you create a class (extending the c_TestFactoryObject interface), and create data from it in your test (*c_TestFactory.make(MyObject.class)* and *run()* to generate your sObjects and insert them) the factory performs some reflection, and uses the class token *MyObject.class* passed instead and generates the instance for you. It also pays attention to the order you create your objects, so if you create a User then an Account then another User, the DML insert order will be User (list of) and then Account. It's very neat and actually reduces code complexity.


#### Process is now
1) Create your object, inheriting from c_TestFactoryObject. (no changes here, except for eliminating any ENTITY references).
2) Use in your tests: sObject a = (sObject) make(myTemplateClass.class [, new sObject(my overrides)]); *[] denotes optional*

ex. 
```Apex
Account a = (Account) make(DemoObjects.DemoSalesAccount.class, new Account(name='My App Account'));
run();
```

**You can still use your old templates with minor updates. If you have overriden any make() methods on your templates, note the new syntax for calling this method has changed:**

Old: c_TestFactory.make( **c_Testfactory.MYOBJECT_ENTITY**, new sObject(values));

New: c_TestFactory.make( **myObject.class**, new sObject(values)); // note the mandatory .class extention denoting a Type

#### Simple!

## Outstanding Issues?
ONE - sadly Polymorphic field references in Apex can't hold sObjects, so when wiring up WhoId or WhatId on Task for example you will get errors :(
Test this by comparing the following two lines of code:
```Apex
// If you run this in anonymous apex you wont see any errors
Account acc = new Account(name='My account');
Asset a = new Asset(name = 'Asset 123', Account=acc);

// However polymorphic sObject fields behave differently
Account acc = new Account(name='My account');
Task t = new Task(name = 'Task 345', What=acc); // this won't even compile!

Account acc = new Account(name='My account');
insert acc;
Task t = new Task(name = 'Task 345', WhatId=acc.Id); // this will be OK
```
The answer is to insert (run) the factory before creating these objects. This isn't always ideal, and one could create an extension ot the FactoryObject to map these. I'd be grateful for anyone who wants to write an extension to that interface!

### Important notice for performance
Since API v 43, Salesforce has been seeing CPU issues with describe calls. In order to work around this, optimisations have been made to this code (you can see these in the CPU Improvement branch recently merged). Describe calls are still used however, and it is recommended that the critical update in Spring '20, "Use Improved Schema Caching" is enabled in your org.

More information can be found in this KB  article: https://success.salesforce.com/issues_view?id=a1p3A000001RXBZQA4&title=sobjecttype-getdescribe-and-sobjectfield-getdescribe-increase-apex-cpu-consumption-in-api-version-44

## About
This project provides a test framework for for Apex unit tests on the Salesforce lightning platform. The framework provides a scaffold for automating and reusing test data to make the development lifecycle more predictable and efficient. 

Using the framework allows developers to:

- Rapidly scaffold a unit test, and promote test driven development
- Create and extend simple and complex business objects based on templates from other developers to speed up development time, with minimal conflicts, maximise re-use, and minimise waste
- Automate data generation consistently
- Minimise DML cycles by grouping together similar object types
- Mandate the order of database creation when generating data so that relationships can be maintained
- Side step the framework when necessary in a consistent way
- Work effectively with breaking changes from configurators or other projects, with a central place to define business objects used by tests (1) - critical in SIT testing
- Centralise common functionality for unit tests ex. a "Use Large Data Sets in Tests" option (2) - critical when it comes to production deploys

(1) When a change is made, it's good that tests fail! And it's even better that there is one place to fix the code.
(2) It's important to test code at bulk, but once it's been tested it also slows down the org and deployment. Instead, developers can use a flag to switch from generating massive amounts of bulk data to a small number of records.

## Why use a framework?
One major problem in Enterprise scale Salesforce projects is they are often riddled with bugs caused by Apex being written without clear test cases (ie. no Test Driven Development). Partly due to debugging in Apex being a very poor experience, but also due to the complex setup of data and hoops developers have to jump through just to get to the state they are testing for. In the end, developers often ship code that only has test coverage (the minimum 75%) that doesn't really test the intended outcome. 

Generating data for testing a data driven platform is a massive pain, especially in an agile project environment where the data surfaces of sObjects, security, profiles and users rapidly change. One change can cause spaghetti, so as developers try to keep things simple, which results in problems later down the line when they find out their code doesn't merge or work in real life situations. Data in tests is vital.

Basic approaches used by project developers include providing a set of methods that generate common data structures such as users, or Accounts - which works fine for simple environments. As projects grow, and dependencies and DML limits become an issue, developers need a consistent way to work together to save time and generate predictable data to work with to be sure they have achieved the aim of the story or requirement - test driven development, especially, demands this.

## In Use
Using the framework is straightforward. A developer creates a default template for re-use by writrng a class that extends c_TestFactoryObject, and then when writing tests, instantiate the template (with optional overrides) and have the factory commit to the database in grouped DML to reduce overhead. 

There is also a test user and accompanying profile "UnitTestSetupUser" provided, which allows you to use a speciffic user when creating your set up data. This is a recommended way to avoid firing triggers etc. if you know how to use Custom Permissions to reduce any overhead when creating Set up data by associating custom pemrissions to your test user's profile and checking for them in your automation scripts you wish to suppress. Quite neat ;)

### Classes
Two main classes

1) The main factory class c_TestFactory
2) and an Object class c_TestFactoryObject

c_TestFactory is used to generate data for tests
c_TestFactoryObject is used as the boilerplate for creating object templates

Some example classes have been provided in the Demo folder, and also the c_TestFactorySatandardUsers class has some nice examples of how to perform inherritance, if thats what you want. (Ie reuse of one template by another).


## c_TestFactory 
Does three jobs:
1. Manage Test Context (country, language etc.)
2. Generate data from templates
3. Register and insert the generated data to the database

#### 1. Test Context
Good tests run in a consistent context, ie predictable values such as language, country, email encoding formats, data volumes. This ensures that you are able to vary the context of the tests being run in a predictable way, both as a developer and a tester.

The test factory uses a custom metadata table “Test Settings” *c_TestSettings__mdt*

In this table you create a context with the following fields that are looked up at runtime:

- BULKIFY_TESTS__c - True / False,
    -  A toggle for your test scripts to check to define how much data to enter. Tests can be very slow using large data volumes, so for a release make sure this is set to FALSE. For development however set this to TRUE and test your trigger methods are bulkified!
- COUNTRY_CODE__c - standard salesforce ISO country code
- COUNTRY_NAME__c - country name
- CURRENCY_ISO_CODE__c - standard salesforce ISO currency code
- EMAIL_ENCODING_KEY__c - encoding to use in emails generated in code, ex. UTF-8
- LANGUAGE_LOCALE_KEY__c - standard salesforce language locale ex. en_US
- LOCALE_SID_KEY__c - standard salesforce locale sid key ex. en_US
- TIMEZONE_SID_KEY__c - standard salesforce timezone sid key ex. Europe/Helsinki
- Active__c - tells the test factory to use this rule

The test factory will use the most recently created row marked *Active* and store these in static fields (so that you can override them as needed).

#### 2.Generate data from templates
Extend the factory in your Test to allow access to it's methods. Thisn is optional as you can also enter "c_TestFactory" everywhere, this just simplifies your code a little:

@IsTest
public class DemoTest extends c_TestFactory {
    /***
     * Demo using the DemoObjects availale
     */

    @TestSetup
    static void demoTestSetUp(){
        ...

Use the "make" method to create an object from a template. You will need to know what object you are creating!
Note, all objects must have UNIQUE names. myDomain_Objects.Asset will get confused with anotherApp.Asset. 

Create data in memory: "Make"
- make(myObject.class) // creates a default sObject of myObject from the myObject template. Note the extension "class" passes the token for the framework to use
- make(myObject.class, new sObject(someField='my override')); // the fields you pass in the sObject will get used by the template and override the default values.

and then insert everything in memory to the database: "Run"
- Run() - inserts everything in memory and flushes the buffer. If you dont need the data in the db, dont run this.

Example. Create a user using the objects built into the provided c_TestFactoryStandardUsers class:

```Apex
User myUser = make(c_TestFactoryStandardUsers.UnitTestSetupUser.class, new User(alias='TestUsr'));
run();
```

#### 2. pt 2 How the factory creates the data in the db (this is the clever bit)
- A generic "run" method loops through all the "made" objects and inserts them into the database.
- The "run" is called, the queue of objects is processed, grouped by name, and reflection is used to automatically link up any ID's while they are inserted into the database by field name.

```Apex
@isTest
public class exampleTest extends c_TestFactory {

    @TestSetup
    public static void setUp() {
        // Requesting a User (in this case a specical end user who works at the country level of our business) to be built with all defaults needed,  overriding the username and alias fields according the the developers options

        User salesUser = (User) make(c_TestFactoryStandardUsers.StandardUser.class, new User(username = 'my_special_name@user.example.com', alias = 'ctrusr')); 

        // The user is then made an owner of a Sales Account, and a Sales Opportunity is created too, as a child of both.

        Account customerAccount = (Account) c_Testfactory.make(DemoObjects.DemoSalesAccount.class, new Account(Owner = salesUser));
        
        Opportunity customerOpty =  c_Testfactory.make(DemoObjects.DemoSalesOpportunity.class, new Opportunity(Account = customerAccount, Name = customerAccount.name +' Test Oppty '+i));

        // Now the factory processes the object(s) and inserts them to the database. The factory knows the order of the objects, by following the 
        run(); 

        // All the data is inserted with IDs connecting each record as you may expect
    }
}
```

## c_TestFactoryObject
This lean class provides an interface so that the factory can automate the building of data, both complex and simple.

Creat a class extending c_TestFactoryObject to provide the interface the factory needs: 

* Create an Apex class [CollectionName] to contain your new object (or add to en existing)
    * This will contain all your objects that are related to one another. Typically you may wish to do this per project or cloud. ex. MyNameSpace_SalesCloud
* Create a class extend from c_TestFactoryMaker.
* *For simple business object* (one sObject, no children):
    *  Define the default() method, returning an sObject with default values.

```Apex
    public class SalesAccount extends c_TestFactoryMaker {
        sObject defaults() {
            Account rec = new Account();
            // Default values
            rec.Name = 'A Customer Account';
            return (sObject) rec;
        }
    }
```
* *For complex ‘composite’ objects* (a sObject with one or more complex relationships) 
    * Tack together simpler business objects into one larger object, such as a Customer (which would be an account, and some contacts perhaps, maybe even a basic opportunity and a case or lead etc.). 
    * Create your class, then Define the default() method to return null. 
    * Override the make method: 
```Apex
    public class Customer extends c_TestFactoryMaker {
        sObject defaults() {
            return null; // optional you can still provide some defaults
        }

        public override sObject make(sObject sourceObject) {
            // Your custom code is going to go here
        }
    }
```
* When combining objects, you can pass whole sObjects as a reference value. This way you can build up a structure of objects, such as Accounts with Contacts and Opportunities, cases etc.

```Apex
    public class Customer extends c_TestFactoryMaker {
        sObject defaults() {
            return null;
        }
        
        // Custom override for the maker
        public override sObject make(sObject sourceObject) {

            // Use existing Account, Contact and Opportunity templates together 
            // to create an account with a contact and an opportunity
            // Note that we dont set ANY Id's :) instead we assign the sObjects themselves. The factory class applies reflection when inserting the records to wire up the ID fields
            
            Account customerAccount = (Account) c_Testfactory.make(DemoObjects.DemoSalesAccount.class, (Account)sourceObject);
            
            c_Testfactory.make(new DemoObjects.DemoSalesContact(), new Contact(Account = customerAccount, FirstName = contactFirstName, LastName = 'Contact '+i, Email = contactUniqueEmail));
            
            c_Testfactory.make(DemoObjects.DemoSalesOpportunity.class, new Opportunity(Account = customerAccount, Name = customerAccount.name +' Test Oppty '+i));
            
            // Return the passed Account object as a root reference
            return (sObject) customerAccount;
        }
    }
```

## Using the factory in a Unit Test

### DemoTest
This class contains a small demo of how to build an Account hierachy, and use different features of the framework. Note that it focuses on the **TestSetUp** which is where the framework is most useful.

### Updating / Extending an existing object
Often you will have additional values to add as default, like required values or expected values. 

Go to the class ex. DemoObjects.DemoSalesAccount

Each class extends the TestFactoryMaker class, and as such contains a default method for that object. Here you can make sure the basic fields are set as you need, adding or updating as required. If it’s a complex data type with child records etc, usually editing the components the complex data type builds from is enough and you don’t need to edit the complex object itself.

Updating a template can cause other tests to fail - this is a GOOD thing, as it means those tests need updating as the data model has changed. Get them up to date!

## Q&A
### Ideas for improvement
- Error handling and reporting of failures to enable trend analysis of common development / SIT problems
- Include the new EventBus delivery methods as well as DML. Now that would be cool.

### Is it really a framework?
Technically not, though it does have interfaces that mandate certain footprints and coding styles, it is more of a 'pattern'; however this repo can be used directly as base code and extended easily, so the answer is also 'Yes'. Other examples of frameworks in apex include Kevin O'Hara's excellent Light Weight Trigger Framework.

### I want to improve it and have decided to refactor the lot
Cool, if it's a major refactor make a pull request... My only ask is to to try keep this simple, having boiled it down from some earlier heavy structures already.

### How can I quickly validate my Maker Classes when I write t

Some anonymous code is provided in the AnonApexForTesting folder to help you try out your work. 
