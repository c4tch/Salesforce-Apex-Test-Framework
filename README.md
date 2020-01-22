# A Salesforce Apex Unit Test Framework for Agile Teams

## About
This project provides a framework to scaffold templates of data for reuse in Apex unit tests on the Salesforce lightning platform, making it easier for developers to write test cases that work with reliable data, improving developer flow and stability of releases.

<a href="https://githubsfdeploy.herokuapp.com?owner=Matthew Evans&repo=https://github.com/c4tch/SFDCTestFramework&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

Features:
1) Rapidly create reusable Templates for data for each business scenario. (A Case for your B2C business will not be likely to be the same as your B2B business or Back office support for example.)
2) Represent data as simple records, or complex dependent (parent / child) data^.
3) Define common settings such as Country or Currency using a test wide set of Context variables that will be used by the templates.
4) Use flags to choose if you want to run tests with bulk data, or with a small number of records (faster, and more useful for Continuous Integration testing or final releases).
5) Templates can be extended / overridden and inherrited, allowing efficient code reuse.
6) Framework intelligently gathers DML cycles together, massively reducing DML when generatring test data. This speeds up your tests and reduces the use of governor limits.
7) Speeds up unit test writing. Once a template has been created it can be re-used accross your application.

*^Simple examples could be different types of User, Accout, Contact, or Opportunity. Complex examples may be a composition of dependencies, like a Customer (An account, with multiple contacts, opportunities, cases etc. The framework allows you to stitch together relationships in memory, even before the records have not been committed to the database.*

### Important notices
#### Source Format
To make it easier to deploy this code using SFDX the git repo is now in Source Format. It is recommended to create a base package using this code as-is (removing examples) and then extending it for your projects. 

#### Performance
Since API v 43, Salesforce has been seeing CPU issues with describe calls. In order to work around this, optimisations have been made to this code. Describe calls are still used however, and it is recommended that the critical update in Spring '20, "Use Improved Schema Caching" is enabled in your org.

More information can be found in this KB  article: https://success.salesforce.com/issues_view?id=a1p3A000001RXBZQA4&title=sobjecttype-getdescribe-and-sobjectfield-getdescribe-increase-apex-cpu-consumption-in-api-version-44

## Why use a test framework?
One major problem in Enterprise scale Salesforce projects is they are often riddled with bugs caused by Apex being written without clear test cases (ie. no Test Driven Development). Partly due to debugging in Apex being a very poor experience, but also due to the complex setup of data and hoops developers have to jump through just to get to the state they are testing for. In the end, developers often ship code that only has test coverage (the minimum 75%) that doesn't really test the intended business outcome. 

Generating data for testing code on a data driven platform is a massive pain - especially in an agile project environment where the data surfaces of sObjects, security, profiles and users rapidly change. Data in tests is vital.

## Earlier solutions
Most projects create one or more Apex classes that developers use as a 'Test factory' to generate common data such as users, or Accounts - an approach which works fine for simple environments and smaller apps. As projects grow with dependencies these methods soon become limited and DML limits become an issue. Context (user country or currency the test should be using) may also need to be changed depending on the business area being developed for as well.

This framework allows data to be modelled consistently for any use case, and the developer to control not only how and when DML is executed but also the context of tests and be sure the relationships and deperndencies are predictable and maintainable for everyone and can be sure they have achieved the aim of the story or requirement - test driven development, especially, demands this.

## In Use (short version)
We are going to create data for a basic test featuring an Account with a child Opportunity. This uses two templates SALES_ACCOUNT and SALES_OPPORTUNITY that we assume already exist (in the project here these are provided as examples to be edited). Best practice is to put your data generation into a @TestSetup method, see here for more information (https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_testsetup_using.htm), however we will keep this simple by generating our data in the unit test method:

Assuming we have created our two templates already, in our Unit Test we do the following:

1) Extend the Unit Test class to use the factory
```Apex
@isTest
public class myProject_SampleUnitTest extends c_TestFactory {
    @isTest
    private static void myUnitTest() {
        // My test will go here
    }
}
```

2) Inside your unit test, set the context of the test data
```c_TestFactory.setDefaultContext();```
*This fetches the context from the Customer metadata type "Test Settings". You can also override them in Apex directly by referencing the static variables c_TestFactory.COUNTRY_CODE etc.*

3) Create the data you want in memory. 
```Apex
Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account '));
Opportunity o = (Opportunity)  make(Entity.SALES_OPPORTUNITY, new Opportunity(name = 'My opty', Account = a));
```
*See how we can Parent the Opportunity before anything has be committed to memory? Neat! The factory registers the templated data and their relationships as you call them into memory.*

4) Now, execute the DML in one go and you can start your test
```Apex
run();
```

The final code might look like this:
```Apex
    @isTest
    public class myProject_SampleUnitTest extends c_TestFactory {
        @isTest
        private static void myUnitTest() {
            Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account '));
            Opportunity o = (Opportunity)  make(Entity.SALES_OPPORTUNITY, new Opportunity(name = 'My opty', Account = a));
            run();
            
            Test.startTest();
            // do my tests here
            Test.stopTest();
        }
    }
```

### So what's happening? 

First we extend the class to use c_TestFactory - allowing us to access the factory easily, and set the context (see below "c_TestFactory / Test Context" for the full list of context variables)

Next we create data in memory using "make". This has two signatures, one to get the default values and another to be able to inject your own variations:

- make(Entity.MY_OBJECT_NAME) - creates a default sObject of MY_OBJECT_NAME in memory from the MY_OBJECT_NAME template
- make(Entity.MY_OBJECT, new sObject(someField='my override'); - optional, allows pass in of an sObject to override default values, can set any valid field this way, including relationship and allows passing of other sObjects in memory)

The c_TestFactory class keeps a list of template names and maps each one to a method that generates the default data. When the "make" method is called, the factory looks up the correct class and passes on any data you want to seed the sObject(s) with such as Name or any relationship fields, like we do with the child Opportunity.

Then everything is inserted from memory to the database: "Run"
- Run() - inserts everything in memory and flushes the buffer

Once a developer has "made" their data, the factory will then insert the sObjects in the most efficient way, which helps keep the number of DML cycles down. (Which can be a problem in large, complex orgs).

This avoids creating different data footprints for every project and code initiative, while still allowing for refactoring and customisation.

## Creating a new template
Several example tempaltes have bee provided, including a sample unit test. It might be best to look at those before creating your own so that you can become familiar with the pattern. These are detailed below in the ***Framework Contents*** section.

To create a new Entity template:

1) Create your class

Create an Apex class **[Namespace][TestFactory][CollectionName]** to contain your new object (or add to en existing class). This must **extend from c_TestFactoryMaker** . This class will contain all your objects that are related to one another. Typically you may wish to do this per project or cloud. ex. MyNameSpace_TestFactory_SalesCloud.

A template can be built in several ways, however the minimum requirement is to have a default() method to return a basic sObject with some standard values.

*A simple business object* (one sObject, no children):

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

The default method is called by the factory and the result merged with any values passed by the unit test. If you want to process the result of the merge there is the 'make' method available to override. In this example, we set some default value, the factory then calls the make method at run time and to update the username, making it easier to manage and avoid any conflicts.

*A simple business object with custom functionality* (one sObject, no children, custom behaviour):
```Apex
    /**
    * Standard User 
    **/
    public class StandardUser extends c_TestFactoryMaker  {

        sObject defaults()
        {
            // Default object
            User rec = new User();
            String orgId = UserInfo.getOrganizationId();
            
            // Default values
            rec.Alias = 'SysAdmin';

            rec.EmailEncodingKey = EMAIL_ENCODING_KEY; // Context values taken from the Factory
            rec.LanguageLocaleKey = LANGUAGE_LOCALE_KEY;
            rec.LocaleSidKey = LOCALE_SID_KEY;
            rec.TimeZoneSidKey = TIMEZONE_SID_KEY;

            return (sObject) rec;
        }

        // Custom maker method allowing us to set the username based on any custom alias value provided
        // making it easier to identify records created
        public override sObject make(sObject sourceObject) {

            // get and merge defaults
            sObject rec = (sObject) defaults();
            sourceObject = mergeFields(rec, sourceObject);

            // Custom logic to Update the username based on Alias if it's not the same as the default
            if (((User)sourceObject).Alias!=null && ((User)sourceObject).username == ((User)rec).username) {
                String orgId = UserInfo.getOrganizationId();
                ((User)sourceObject).username = ((User)sourceObject).Alias + '@'+ orgId+'.anytest.com';
            }

            // Add to the Templates's list of records created and return the result for this record
            add(sourceObject);

            return (sObject) sourceObject;
        }
    }
```

The framework can also be used to create complex data entities, with dependencies. 

This allows you to tack together simpler business objects into one larger object, such as a Customer (which could be an account, some contacts, a basic opportunity and a case etc.).

While this is useful generating allot of data may blow DML limits (20 customers each with 100 oportunities and 100 cases would be 2000 rows and allot of triggers etc.) so composite objects should be limited to generating data to test particular situations.

* Create your class and Define the default() method to return basic values or even return null (as there may be no base sobject). 
* Override the make method to collect your data into one object

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

2) Register your new template in the Test Factory
Edit the **c_TestFactory** class to register the new object. 

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

## Updating / Extending an existing object
Often you will have additional values to add as default, like required values or expected values. 

Go to the class that’s mapped in TestFactory, ex.:
```Apex
Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
```

Each class extends the TestFactoryMaker class, and as such contains a default method for that object. Here you can make sure the basic fields are set as you need, adding or updating as required. If it’s a complex data type with child records etc, usually editing the components the complex data type builds from is enough and you don’t need to edit the complex object itself.

Updating a template can cause other tests to fail - this is a GOOD thing, as it means those tests need updating as the data model has changed. Get them up to date!

## Framework Contents

### Classes
Three main classes, the main factory class which you will edit, an two you won't need to touch: an automation class (the one that creates and inserts data to the database) and an abstract Maker which is the base for creating your own objects so that the factory has a predictable set of methods and accessors.

- c_TestFactory (EDITABLE) - your **test class** can "extend" this, allowing your tests to access the factory without writing c_TestFactory zillions of times.
- c_TestFactoryMaker - your **templates** will "extend" this, which makes sure you have the methods that the factory can recognise.
- c_TestFactoryAutomation - the "engine" of the framework - no need to touch this.

Some example classes have been provided to demonstrate how to build different kinds of business objects, or Entities, for use in Tests. These can be rewritten / replaced as needed:
- c_TestFactory_Users (like business users)
- c_TestFactory_CoreUsers (like sys admin)
- c_TestFactory_SalesCloud (accounts, contacts, optys, customers with contacts etc.)

Finally, a sample unit test has been provided
- myProject_SampleUnitTest

## Pre existing objects for editing and reuse: c_TestFactory_CoreUsers, c_TestFactory_Users and c_TestFactory_SalesCloud
Three example implementations of creating users and Sales Cloud objects are provided.

Objects are built using 'maker' classes, simple classes extending c_TestFactoryMaker. As their most simple (and common use), a maker class only has to provide the default values for a basic sObject. The following snipped shows how a SalesAccount is created.

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

## c_TestFactory 
Does three jobs:
1. Keep a register and map of the Entities to classes that generate the data
2. Manage Test Context

### c_TestFactory / Mapping 'Entity' template labels to classes
The factory keeps a list of Entities (your templates get a nice friendly name so that we can differenciate between the differnt kinds of Account or Opportunity you might build). These are mapped to the methods that generate the data.

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

### c_TestFactory / Test Context
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
    
    c_TestFactory.setDefaultContext();
    
    Account a = (Account) c_TestFactory.make(c_TestFactory.Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account '));
    
    Opportunity o = (Opportunity)  c_TestFactory.make(c_TestFactory.Entity.SALES_OPPORTUNITY, new Opporunity(Account = a, ouhoiuhjoihj));

    c_TestFactory.run();

Database.rollback(s);
```

## Notices
### (21-01-2020) Migration from Metadata format to Source format COMPLETE
Inline with the DX roadmap all c4tch repos will be moved to source format, including this one. A branch will be kept with the 'old' code for prosterity, however a new master will be used. You can expect the change to ocurr within the next few days. 

### (16-12-2019) Unit tests for framework to be included COMPLETE
One project implementing this solution was reporting the need for the test framework itself to include unit tests. As the framework is extended by you and used in your own tests this was originally considered to be a 'nice to have', however as the request was clear that it was necessary for alpha deploys and initial set up it made sense. This has been completed and will be added to the repo Jan 2020.
