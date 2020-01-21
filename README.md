# A Salesforce Apex Unit Test Framework for Agile Teams
## Notices
### (21-01-2020) Migration from Metadata format to Source format iminent
Inline with the DX roadmap all c4tch repos will be moved to source format. A branch will be kept with the 'old' code for prosterity, however a new master will be used. You can expect the change to ocurr within the next few days. 

### (16-12-2019) Unit tests for framework to be included
One project implementing this solution was reporting the need for the test framework itself to include unit tests. As the framework is extended by you and used in your own tests this was originally considered to be a 'nice to have', however as the request was clear that it was necessary for alpha deploys and initial set up it made sense. This has been completed and will be added to the repo Jan 2020.

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

## Why use a test framework?
One major problem in Enterprise scale Salesforce projects is they are often riddled with bugs caused by Apex being written without clear test cases (ie. no Test Driven Development). Partly due to debugging in Apex being a very poor experience, but also due to the complex setup of data and hoops developers have to jump through just to get to the state they are testing for. In the end, developers often ship code that only has test coverage (the minimum 75%) that doesn't really test the intended outcome. 

Generating data for testing a data driven platform is a massive pain, especially in an agile project environment where the data surfaces of sObjects, security, profiles and users rapidly change. One change can cause spaghetti, so as developers try to keep things simple, which results in problems later down the line when they find out their code doesn't merge or work in real life situations. Data in tests is vital.

Basic approaches used by project developers include providing a set of methods that generate common data structures such as users, or Accounts - which works fine for simple environments. As projects grow, and dependencies and DML limits become an issue, developers need a consistent way to work together to save time and generate predictable data to work with to be sure they have achieved the aim of the story or requirement - test driven development, especially, demands this.

## In Use
Using the framework is straightforward. A factory class provides access to a generic "Make" method that allows developers to create business objects on the fly (I use the term business objects instead of sObjects as a business object may be a collection, or have different default values than a generic Account for example). 

The built objects are based on templates provided by a factory "Maker" class, and allows developers to tailor them to the unit test being written. 

Once a developer has "made" their data, the factory will then insert the sObjects in the most efficient way, which helps keep the number of DML cycles down. (Which can be a problem in large, complex orgs).

This avoids creating different data footprints for every project and code initiative, while still allowing for refactoring and customisation.

## In Use
The following guides you through the contents of the framework in this project:

### Classes
Three main classes, the main factory class, an automation class (the one that creates and inserts data to the database) and an abstract Maker (the base for creating your own objects so that the factory has a predictable set of methods and accessors).

- c_TestFactory (EDITABLE) - your test class should "extend" this, and you can register your object templates here
- c_TestFactoryAutomation (DO NOT EDIT) - the main database operations, no need to touch
- c_TestFactoryMaker (DO NOT EDIT) - your object templates "extend" this

Some example classes have been provided to demonstrate how to build different kinds of business objects, or Entities, for use in Tests. These can be rewritten / replaced as needed:
- c_TestFactory_Users (like business users)
- c_TestFactory_CoreUsers (like sys admin)
- c_TestFactory_SalesCloud (accounts, contacts, optys, customers with contacts etc.)

Finally, a sample unit test has been provided
- myProject_SampleUnitTest

The next sections will walk through the function of the factory classes and explain how the framework is used.

## c_TestFactory 
Does three jobs:
1. Allow tests to generate data
2. Manage Test Context
3. Keep a register of the Entities used to generate test data

#### 1. Test use the factory to generate data
This class taps into the maker and automation classes to automate the generation of any data requesed in a test. A test gain access to the factory by EXTENDING from this class:

@isTest
public class myProject_SampleUnitTest extends c_TestFactory {
}

The following two methods are available 
Create data in memory: "Make"
- make(Entity.MY_OBJECT_NAME) - creates a default sObject of MY_OBJECT_NAME in memory from the MY_OBJECT_NAME template
- make(Entity.MY_OBJECT, new sObject(someField='my override'); - optional, allows pass in of an sObject to override default values, can set any valid field this way, including relationship and allows passing of other sObjects in memory)

and then insert everything in memory to the database: "Run"
- Run() - inserts everything in memory and flushes the buffer

For a working example, see the example unit test included in the code package.

#### 2. Test Context
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

#### 3. Keep a register of the Entities used to generate test data
The class contains an ENUM called Entity, this lists all the busines objects your tests can use to generate data as friendly names, and also represents the order in which the objects will be inserted to the database. (Its also where you append new objects to as you develop them):

```Apex
    public enum Entity {
        //...The order is IMPORTANT!!! 
        // It defines the order of the DML. 
        // If you need one object inserted before another, 
        // this must be reflected here.
        ADMIN_USER
        ,COUNTRY_USER
        ,SALES_ACCOUNT
        ,SALES_CONTACT
        ,SALES_OPPORTUNITY
        ,CUSTOMER
        //...Add more here as you go...
    }
```
These are mapped to classes that extend the TestFactoryMaker interface, which are used to generate the test data:

```Apex
    // This map points to the maker class that will generate each Entity's sObject(s) for me

    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {
            //... just showing the Sales Account one here to keep this readable
            ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount() 
            //...
    };
    ...
```

## c_TestFactoryAutomation
1. Allow a test to generate sObjects from these entities
2. Insert the generated objects, grouping DML and automatically building relationships between sObjects (this is the clever bit)

#### 1. Allow a test to generate sObjects from these entities
Each of these Entities is mapped to a class to generate the sObject data in c_TestFactory. The purpose of having this index allows the automation to have a single point for developers to "make" sobjects from these Entities in an automated way.

- As Entities are registered here a common "make" method in the factory allows a test to call up any of these. The automation class executes this making process to create an entity in working memory.

#### 2. Insert the generated objects, grouping DML and automatically building relationships between sObjects (this is the clever bit)
- A generic "run" method is then called that loops through all the "made" objects and inserts them into the database.
- The "run" is called, the queue of objects is processed, grouped by name, and reflection is used to automatically link up any ID's while they are inserted into the database.

```Apex
@isTest
public class exampleTest extends c_TestFactory {

    @TestSetup
    public static void setUp() {
        // Requesting a User (in this case a specical end user who works at the country level of our business) to be built with all defaults needed,  overriding the username and alias fields according the the developers options

        User salesUser = (User) make(Entity.COUNTRY_USER, new User(username = 'my_special_name@user.example.com', alias = 'ctrusr')); 

        // The user is then made an owner of a Sales Account, and a Sales Opportunity is created too, as a child of both.

        Account customerAccount = (Account) c_Testfactory.make(Entity.SALES_ACCOUNT, new Account(Owner = salesUser));
        
        Opportunity customerOpty =  c_Testfactory.make(Entity.SALES_OPPORTUNITY, new Opportunity(Account = customerAccount, Name = customerAccount.name +' Test Oppty '+i));

        // Now the factory processes the object(s) and inserts them to the database. The factory knows the order of the objects, by following the 
        run(); 

        // All the data is inserted with IDs connecting each record as you may expect
    }
}
```
*Example shows the make called from a unit test. When ever the "make" methods are called, the results are added to the test factory's working memory, and when "run" is called they are committed to the database in one go in a speciffic given order defined in the Entity list. Note the Class wrapping the unit test extends c_TestFactory*

## c_TestFactoryMaker
This lean class provides an interface so that the factory can automate the building of Entities, both complex and simple.

An Entity's sObjects are built using 'maker' classes, simple classes extending c_TestFactoryMaker. 

To create a new Entity template:

1) Create your class

* Create an Apex class [Namespace][TestFactory][CollectionName] to contain your new object (or add to en existing)
    * This will contain all your objects that are related to one another. Typically you may wish to do this per project or cloud. ex. MyNameSpace_TestFactory_SalesCloud
* Create a class extend from c_TestFactoryMaker.
* *For simple business object* (one sObject, no children):
    *  Define the default() method, returning an sObject with default values.

```Apex
    public class SalesAccount extends c_TestFactoryMaker {
        sObject defaults() {
            // Default object
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
            
            Account customerAccount = (Account) c_Testfactory.make(Entity.SALES_ACCOUNT, (Account)sourceObject);
            
            c_Testfactory.make(Entity.SALES_CONTACT, new Contact(Account = customerAccount, FirstName = contactFirstName, LastName = 'Contact '+i, Email = contactUniqueEmail));
            
            c_Testfactory.make(Entity.SALES_OPPORTUNITY, new Opportunity(Account = customerAccount, Name = customerAccount.name +' Test Oppty '+i));
            
            // Return the passed Account object as a root reference
            return (sObject) customerAccount;
        }
    }
```

3) Register it to the factory
Edit the c_TestFactory class to register the new object. 

Add the business name of the object you are templating to the "Entity" enum in c_TestFactory and map the class. 

The Entity name should be a sensible, human readable name such as SALES_USER or SYSTEM_ADMIN or CUSTOMER. It doesnt need to be (shouldn't be) the name of the sObject as you may want different types of the same object depending on the business needs. 

```Apex
    public enum Entity {
        //...The order is IMPORTANT!!! 
        // It defines the order of the DML. 
        // If you need one object inserted before another, 
        // this must be reflected here.
        ADMIN_USER
        ,SALES_ACCOUNT
        ,SALES_CONTACT
        ,SALES_OPPORTUNITY
        ,CUSTOMER // our new object goes after the atomic records we need created first
        //...Add more here as you go...
    }
    
    // Map a reference to the new class in c_TestFactory from the ENUM in the map 'makers'

    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {
            /*...Map your Entity labels to their maker class here...*/
            // lots missed out here to save space :)
            ,Entity.CUSTOMER  => new c_TestFactory_SalesCloud.Customer()
            //...Add more here as you go...*/
    };
```

## Pre existing objects for editing and reuse: c_TestFactory_CoreUsers, c_TestFactory_Users and c_TestFactory_SalesCloud
Three example implementations of creating users and Sales Cloud objects. Objects are built using 'maker' classes, simple classes extending c_TestFactoryMaker. As their most simple (and common use), a maker class only has to provide the default values for a basic sObject. The following snipped shows how a SalesAccount is created.

```Apex
public class c_TestFactory_SalesCloud {
    public class SalesAccount extends c_TestFactoryMaker {

        // Mandatory minimum default set up, returns an sObject, in this case a default Account for the Sales Cloud
        sObject defaults() {

            // Default object
            Account rec = new Account();

            // Default values
            rec.Name = 'A Customer Account';
            rec.ShippingStreet = 'Nr 1 Some Street';
            rec.ShippingPostalCode = '11111';
            rec.ShippingCity = 'A City';
            rec.ShippingCountry = countryName;

            return (sObject) rec;
        }
    }
}
```

## Using the factory in a Unit Test

### Basic use of the framework (pseudo code)
In this example three entities SALES_USER, SALES_ACCOUNT, SALES_OPPORTUNITY have been created for use by the test method:
```Apex
    @isTest
    public class c_OpportunityManager_Test extends c_TestFactory {
        @TestSetup
        static void setUp() { 
            User businessUser = (User) make(Entity.SALES_USER, new User(alias = 'myalias'));
            Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account '));
            Opportunity o = (Opportunity)  make(Entity.SALES_OPPORTUNITY, new Opporunity(Account = a, name = 'Opportunity name'))
            run();
        }
        
        @isTest
        static void testCase() {
            // query for the data inserted by setup
            // do my tests using the businessUser to Run As
        }
    }
```

#### Updating / Extending an existing object
Often you will have additional values to add as default, like required values or expected values. 

Go to the class that’s mapped in TestFactory, ex.:
```Apex
Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
```

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

### How can I quickly validate my Maker Classes when I write them
Use some anonymous apex. Here's an example I wrote after creating the AdminUser maker class to test it out (note there may be limits in your org on the number of Administrator licences, so watch for the org complaining when you execute this dml).

Note that as this is anon apex, there is no class to extend using c_TestFactory, so you'll see that written everywhere...
```Apex
    /*
    SFDX: Execute Anonymous Apex with Currently Selected Text
    or this:
    SFDX: Execute Anonymous Apex with Editor Contents
    */

    System.Savepoint s = Database.setSavepoint();
    
    c_TestFactory.setDefaultContext();Account a = (Account) c_TestFactory.make(c_TestFactory.Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account '));
    
    Opportunity o = (Opportunity)  c_TestFactory.make(c_TestFactory.Entity.SALES_OPPORTUNITY, new Opporunity(Account = a, ouhoiuhjoihj));

    c_TestFactory.run();

Database.rollback(s);
```

