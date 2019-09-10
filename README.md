# A Salesforce Apex Unit Test Framework for Agile Teams

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

## Implementation
The following guides you through the contents of the framework in this project:

### Classes
Two main classes, the main factory class, and an abstract Maker which is used as the base for creating your own objects so that the factory has a predictable set of methods and accessors. (It's an Abstract class, if you want to be specific).

- c_TestFactory
- c_TestFactoryMaker

To Maker classes are provided for creating Users and Sales Cloud objects. These can be rewritten / replaced as needed:
- c_TestFactory_Users
- c_TestFactory_SalesCloud

### Class Details:

#### c_TestFactory 
Does three jobs:
1) Manage Test Context
-Good tests run in a consistent context, ie predictable values such as language, country, email encoding formats, data volumes. This ensures that you are able to vary the context fo the tests being run in a predictable way, both as a developer and a tester.
-These are contained in a set of static values stating the current context you want to run the test in (country, locale etc.). T

The test factory uses a custom metadata table “Test Settings” *c_TestSettings__mdt*
In this table you create a context with the following settings:

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

The test factory will use the most recently created row marked *Active* 

2) Build Objects for use in tests
- A common "make" method allows unit tests to reference and build any objects registered in the class
- A generic "run" method loops through all the "made" objects and inserts them into the database.

```Apex
@isTest
public class c_TestFactory_zzz_SampleUnitTest extends c_TestFactory {
    @TestSetup
    public static void setUp() {
        // The test is requesting an Admin User to be built with all defaults needed, but overriding the username and alias fields according the the developers options
        User adminUser = (User) make(Entity.ADMIN_USER, new User(username = 'my_special_name@user.example.com', alias = 'admis')); 
        // the factory processes the objects and inserts them to the database
        run(); 
    }
}
```
*Example showing the make called from a unit test. When ever the "make" methods are called, the results are added to the test factory's working memory, and when "run" is called they are committed to the database in one go in a given order. Note the Class wrapping the unit test extends c_TestFactory*

3) Register new objects
- Accessors to the business object makers are listed in the Factory class.
- Objects are built using 'maker' classes, simple classes extending c_TestFactoryMaker. The TestFactory has an Entity enum, which represents the order in which the objects will be inserted to the database, and also friendly labels to describe the object being created.

```Apex
public virtual class c_TestFactory ...
    public enum Entity {
        ...
        ,SALES_ACCOUNT // My business object is added to this Entity list. We can use any friendly readable name. It's used as the main label for the object 
        ...
    }
    
    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {
            ...
            ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount() // This map points to the maker class that will generate the object for me
            ...
    };
    ...
```

#### c_TestFactoryMaker
Abstract class stating what a maker class should implement so that the factory knows what it can call, and provides basic core methods

#### c_TestFactory_Users and c_TestFactory_SalesCloud
Two example implementations of creating users and Sales Cloud objects. Objects are built using 'maker' classes, simple classes extending c_TestFactoryMaker. As their most simple (and common use), a maker class only has to provide the default values for a basic sObject. The following snipped shows how a SalesAccount is created.

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

## Create your own 'maker' classes
Creating an object and allowing it to be populated by your own values in a unit test is ridiculously easy. The two example classes included in this project for *Users* and *SalesCloud*. The walkthrough of the samples above explains how these are built.

i) Create your maker class inheriting from c_TestFactoryMaker. Use a sensible naming convention like c_TestFactory_SomeName
ii) Register the maker class in the TestFactory Entity enum and "makers" map
iii) Use it!

When a developer wants a Sales Account now they can use the factory. At the most basic this is two lines:
```Apex
public class myUnitTest extends c_TestFactory {
    make(Entity.SALES_ACCOUNT, (sObject) new Account(name = 'Roger Rabbit ACME Co.'));
    run(); //runs the DML
}
```

For a tip on how to quickly scaffold and test your maker class, see the Q&A section at the end for some useful anon apex tips.

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
#### Using objects in the framework
The framework provides a way to create a template for a business object, above you can see three entities SALES_USER, SALES_ACCOUNT, SALES_OPPORTUNITY  that have been created 
In your tests you request a copy of a speciffic object using human readable names like SALES_USER or CUSTOMER etc. 

#### Updating / Extending an existing object
Often you will have additional values to add as default, like required values or expected values. 

Go to the class that’s mapped in TestFactory, ex.:
```Apex
Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
```

Each class extends the TestFactoryMaker class, and as such contains a default method for that object. Here you can make sure the basic fields are set as you need, adding or updating as required. If it’s a complex data type with child records etc, usually editing the components the complex data type builds from is enough and you don’t need to edit the complex object itself.

Updating a template can cause other tests to fail - this is a GOOD thing, as it means those tests need updating as the data model has changed. Get them up to date!

### Creating your own objects
1) Create your object template

* Create an Apex class [Namespace][TestFactory][CollectionName] to contain your new object (or add to en existing)
    * this will contain all your objects that are related to one another. Typically you may wish to do this per project or cloud. ex. MyNameSpace_TestFactory_SalesCloud
* Create a class extend from c_TestFactoryMaker.
* *For simple business objec*t (one sObject, no children):
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
    * Tack together simpler business objects into one larger object, such as a Customer (which would be an account, and some contacts perhaps, maybe even a basic opportunity and a lead too). 
    * Define the default() method, return null. 
    * Override the make method: 
        public override sObject make(sObject sourceObject) {
              // Your custom code is going to go here
        }
    * When combining objects, you can pass whole sObjects as a reference value. This way you can build up a structure of objects, such as Accounts with Contacts and Opportunities, cases etc.

```Apex
    public class Customer extends c_TestFactoryMaker {

        // Mandatory minimum default set up, return null for complex objects
        sObject defaults() {
            return null;
        }
        
        // Custom override for the maker
        public override sObject make(sObject sourceObject) {
            // Use the exsiting Account, contat and opportunity templates together 
            // to create an account with a contact and an opportunity
            Account customerAccount = (Account) c_Testfactory.make(Entity.SALES_ACCOUNT, (Account)sourceObject);
            c_Testfactory.make(Entity.SALES_CONTACT, new Contact(Account = customerAccount, FirstName = contactFirstName, LastName = 'Contact '+i, Email = contactUniqueEmail));
            c_Testfactory.make(Entity.SALES_OPPORTUNITY, new Opportunity(Account = customerAccount, Name = customerAccount.name +' Test Oppty '+i, RecordTypeId=c_TestFactory_SalesCloud.renewalOpportunityRecordTypeId));
            
            // Return the passed Account object as a root reference
            return (sObject) customerAccount;
        }
    }
```
2) Register it to the factory
Edit the c_TestFactory class to register the new object:

1. Add the business name of the object you are templating to the "Entity" enum in c_TestFactory. This should be a sensible, human readable name such as SALES_USER or SYSTEM_ADMIN or CUSTOMER. It doesnt need to be (shouldn't be) the name of the sObject as you may want different types of the same object depending on the business needs. 

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
2. map a reference to the new class in c_TestFactory from the ENUM in the map 'makers' .

```Apex
    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {
        /*...Map your Entity labels to their maker class here...*/
        Entity.ADMIN_USER => new c_TestFactory_CoreUsers.StandardSystemAdmin()
        ,Entity.COUNTRY_USER => new c_TestFactory_Users.CountryUser()
        ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
        ,Entity.SALES_CONTACT  => new c_TestFactory_SalesCloud.SalesContact()
        ,Entity.SALES_OPPORTUNITY  => new c_TestFactory_SalesCloud.SalesOpportunity()
        ,Entity.CUSTOMER  => new c_TestFactory_SalesCloud.Customer()
        //...Add more here as you go...*/
};
```
3. Use in tests
Once I have created the new object template, you can now use it in tests. Write a test class that extends c_TestFactory, and in my TestSetup I want to create some records.

 To use an object call this way:

(SObjectToken) make(Entity.MY_ENTITY_NAME, new SObjectToken(OptionalFieldToSetManually = ‘override value’, OptionalReferenceField = sObject) 

The sObjectToken would be something like User, Account etc.

Example: 

```Apex
    User businessUser = (User) make(Entity.SALES_USER, new User(alias = 'myalias'));
    Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(Owner = businessUser, name = 'My new Account'));
```
Then perform run() for the factory to execute all the objects and insert in the most efficient way.

```Apex
    run();
```
This way with one line, you have predictable test objects in all your tests. No reason not to do TDD!

Code clip (will not compile!):

```Apex
    public class c_TestFactory_UnitTest_EXAMPLE extends c_TestFactory {
    @TestSetup
    public static void setUp() { 
        // !important! Do this first, it sets the general context, country values etc.
        c_TestFactory.setDefaultContext();
        
        // Create an admin user using a template, I want to override the default alias so I can find it easily
        User adminUser = (User) make(Entity.ADMIN_USER, new User(alias = 'admis'));
        
        // ....create more objects
        
        // I'm done, either I'm finished or I want to get these inserted to the database so I can use their ID's
        run();
```

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

