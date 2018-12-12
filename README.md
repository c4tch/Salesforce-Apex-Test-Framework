# A Scalable Salesforce Apex Unit Test Framework
FAIR WARNING: This is the first commit :) Though it's based on several past projects; improvements and testing are yet to come. Give it a test-drive and let me know of issues.

## About
This project provides a test framework for for Apex unit tests on the Salesforce lightning platform. The framework provides a scaffold for automating and reusing test data to make the development lifecycle more predictable and efficient. 

Using the framework allows developers to:

- Rapidly scaffold a unit test, and promote test driven development
- Create and extend simple and complex business objects based on templates from other developers to speed up development time, with minimal conflicts, maximise re-use, and minimise waste
- Automate data generation consistently
- Minimise DML cycles by grouping together similar object types
- Mandate the order of database creation when generating data so that relationships can be maintained
- Side step the framework when necessary in a consistent way
- Work effectivly with breaking changes from configurators or other projects, with a central place to define business objects used by tests (1) - critical in SIT testing
- Centralise common functionality for unit tests ex. a "Use Large Data Sets in Tests" option (2) - critical when it comes to production deploys

(1) When a change is made, it's good that tests fail! And it's even better that there is one place to fix the code.
(2) It's important to test code at bulk, but once it's been tested it also slows down the org and deployment. Instead, develoeprs can use a flag to switch from genrating massive amounts of bulk data to a small number of records.

## Why use a test framework?
One major problem in Enterprise scale Salesforce projects is they are often riddled with bugs caused by Apex being written without clear test cases (ie. no Test Driven Development). Partly due to debugging in Apex being a very poor experience, but also due to the complex setup of data and hoops developers have to jump through just to get to the state they are testing for. In the end, developers often ship code that only has test coverage (the minimum 75%) that doesn't really test the intended outcome. 

Generating data for testing a data driven platform is a massive pain, especially in an agile project environment where the data surfaces of sObjects, security, profiles and users rapidly change. One change can cause spaghetti, so as developers try to keep things simple, which results in problems later down the line when they find out their code doesn't merge or work in real life situations. Data in tests is vital.

Basic approaches used by project developers include providing a set of methods that generate common data structures such as users, or Accounts - which works fine for simple enviornments. As projects grow, and dependencies and DML limits become an issue, developers need a consistent way to work together to save time and generate predictable data to work with to be sure they have achieved the aim of the story or requirement - test driven development, especially, demands this.

## In Use
Using the framework is straightforward. A factory class provides access to a generic "Make" method that allows developers to create buiness objects on the fly (I use the term business objects instead of sObjects as a business object may be a collection, or have different default values than a genric Account for example). 

The built bjects are based on templates provided by a factory "Maker" class, and allows developers to tailor them to the unit test being written. 

Once a developer has "made" their data, the factory will then insert the sObjects in the most efficient way, which helps keep the number of DML cycles down. (Which can be a problem in large, complex orgs).

This avoids creating different data footprints for every project and code initiative, while still allowing for refactoring and customisation.

## Implementation
The following guides you through the contents of the framework in this project:

### Classes
Two main classes, the main factory class, and an abstract Maker which is used as the base for creating your own objects so that the factory has a predictable set of methods and accessors. (It's an Abstract class, if you want to be speciffic).

- c_TestFactory
- c_TestFactoryMaker

To Maker classes are provided for creating Users and Sales Cloud objects. These can be rewritten / replaced as needed:
- c_TestFactory_Users
- c_TestFactory_SalesCloud

A demo implementation in a sample unit test. Note that the unit test only shows the bare minimum in the TestSetup to generate the data:
- c_TestFactory_zzz_SampleUnitTest

An OrgSettings class*
- c_OrgSettings

\*Contians helper methods. Technically this class can be removed with some minor edits, but it's a useful pattern to use. See below.

### Class Details:

#### c_TestFactory 
Does three jobs:
1) Manage Test Context
-It first has some static vlaues to the current context you want to run the test in (country, locale etc.). This has some hard coded defaults. Adjust these to suit your org, or add a dynamic reference, it's up to you.
```Apex
    /******* Context ******/
    public static String countryCode = 'SE';
    public static String countryName = 'Sweden';
    public static String timeZoneSidKey = 'Europe/Helsinki';
    public static String LanguageLocaleKey = 'en_US';
    public static String LocaleSidKey = 'en_US';
    public static String currencyIsoCode = 'EUR';
    public static String EmailEncodingKey = 'UTF-8';
    public static Datetime now = System.now();
```

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
-Accessors to the business object makers are listed in the Factory class. 
-Objects are built using 'maker' classes, simple classes extending c_TestFactoryMaker. The TestFactory has an Entity enum, which represents the order in which the objects will be inserted to the database, and also friendly labels to describe the object being created.

```Apex
public virtual class c_TestFactory ...
    public enum Entity {
        ...
        ,SALES_ACCOUNT // My business object is added to this Entity list. We can use any friendly readable name. It's used as the main label for the object 
        ...
    }
    
    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {
            //...
            ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount() // This map points to the maker class that will generate the object for me
            //...
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

#### c_TestFactory_zzz_SampleUnitTest
An example test class with pseudo code.

### c_OrgSettings (and custom meta data c__TestSetUp__mtd) - Optional Dependency
The framework introduces a common OrgSettings class where lookups to configuration type data can be made from one place.
- A look up for ProfileId's is provided for example. Results are cached for the length of the transaction. 
- A "Use Large Data Set In Test" flag. Using a custom metadata object c__TestSetUp__mtd unit tests can check to decide when to use large data volumes in tests or not. 

I would encourage this approach to be tailored / refactored to suit the destination org, but not to remove it. Managing common org settings and set up from a global class allows excellent chances for DRY code that mnimises the excess Apex tends to generate.

This is technically an optional class. If you choose to remove it, then it affects the SampleUnitTest where we check the BULKIFY_TESTS() option, and the \_Users class where i use the ProfileID lookup method:.


## Create your own 'maker' templates
Creating a default object and allowing it to be populated by your own values in a unit test is rediculously easy. The two example classes included in this project for *Users* and *SalesCloud*. The walkthrough of the samples above explains how these are built.

i) Create your maker class inherriting from c_TestFactoryMaker. Use a sensible naming convention like c_TestFactory_SomeName
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

### Tour the example
After importing up the code and custom metadata to an org, there is a Sample unit test showing the various ways you can consume the factory.

You can create objects from the factory, or directly from the maker classes. Doing it via the factory means you can automate the generation of the data.

The example tours the sample unit test so see how to use the factory to generate an admin user, some group level accounts, and then nested customer accounts who sit under their corporate group level. Nesting is an important technique required and often hard to get right in data creation.

See how simple objects can be built, and more complex compositions like hierachies can also be managed:

```Apex
    // Set the general context / change the defaults:
    c_TestFactory.LanguageLocaleKey = 'sv';

    // Create some test data...

    // Create key users
    User adminUser = (User) make(Entity.ADMIN_USER, new User(username = 'my_special_name@user.example.com', alias = 'admis'));

    // Create Accounts (high level accounts)
    Account[] topLevelList = new Account[]{
    };

    Integer owningAccounts = c_OrgSettings.BULKIFY_TESTS() ? 20 : 1;
    for (Integer i; i < owningAccounts; i++) {
        Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account ' + i));
        topLevelList.add(a);
    }
    System.assert(topLevelList.size()==owningAccounts, 'Top level group accounts not generated');

    // Upsert all data queued so far. Uders, then accounts. We need the top level account id's to create their child customer records...
    run(); 

    // Create customers (low level accounts - with child contacts)
    for (Account topLevel : topLevelList) {
        Integer customers = c_OrgSettings.BULKIFY_TESTS() ? 11 : 2;
        for (Integer i; i < customers; i++) {
            make(Entity.CUSTOMER, new Account(name = 'Account ' + i, Parent = topLevel));
        }
    }
    System.assert((c_TestFactory.makers.get(Entity.CUSTOMER)).get().size()>0, 'Child accounts not created');

    // Upsert the lower level customers (accounts and contacts)
    run(); 
```

#### Creating an object Directly from a template:
If you want to side step the factory, for what ever reason, you can. Simply reference the maker class directly. You can build your own factory if you want (though ... really...?). Don't forget to extend the wrapping class with c_TestFactory to save you haveing to write c_TestFactory. every time you reference something.

Escencially it's only two lines again to reference a maker:

```Apex
  TestFactoryMaker myAccountMaker = new TestFactory_SalesCloud.SalesAccount();
  Account a = (Account) myAccountMaker.make(new Account());
```

The below example shows how this can be used to demonstrate how maker classes build an in memory list when they are called. This is the main reason that the factory knows what has been built, and is the 'secret' to the DML automation:

```Apex
  TestFactoryMaker myAccountMaker = new TestFactory_SalesCloud.SalesAccount();
  Account a = (Account) myAccountMaker.make(new Account());
  
  System.assertEquals(a.Name, 'A Customer Account');
  System.assertEquals(mySalesAccounts.get().size(), 1); // a reference to the created account is kept in the SalesAccount object
  
  // Create some more if you want to check!
  for (Integer i; i<10; i++)
  {
    mySalesAccounts.make(new Account(name='Another account '+i));
  }
  
  System.assertEquals(mySalesAccounts.get().size(), 11); // a reference to each created account is kept in the SalesAccount object
  
  // Lets side steps the factory compeltely and do it the old way:
  insert (Account[]) mySalesAccounts.get();
```

Or, use the factory make method, and get the same result, except you also get the factory to remember what you did ;). Again, extend the wrapping class with c_TestFactory to save keystrokes:
```
  make(Entity.Sales_Account, (sobject) new Account());
  System.assertEquals(makers.get(Entity.Sales_Account).get().size(), 1); // a reference to the created account is kept in the factory object for later
  
  for (Integer i; i<10; i++)
  {
    make(Entity.Sales_Account, (sobject) new Account(name='Another account '+i));
  }
  
  System.assertEquals(makers.get(Entity.Sales_Account).get().size(), 11); // a reference to each created account is kept in the SalesAccount object
  
  run();
```

## Q&A
### Ideas for improvement
- Error handling and reporting of failures to enable trend analysis of common development / SIT problems
- Include the new EventBus delivery methods as well as DML. Now that would be cool.
- This project overlaps to the OrgSettings area and automation control for example (ie blocking and working with triggers, validation rules and process buider at scale), it might be desirable to abstract these away to make the framework more contained.

### Is it really a framework?
Technically not, though it does have interfaces that madate certain footprints and coding styles, it is more of a 'pattern'; however this repo can be used directly as base code and extended easily, so the answer is also 'Yes'. Other examples of frameworks in apex include Kevin O'Hara's excellent Light Weight Trigger Framework.

### I want to improve it and have decided to refactor the lot
Cool, if it's a major refactor make a pull request... My only ask is to to try keep this simple, having boiled it down from some earlier heavy structures already.

### How can I quickly validate my Maker Classes when I write them
Use some anonimous apex. Here's an example I wrote after creating the AdminUser maker class to test it out (note there may be limits in your org on the number of Administrator licences, so watch for the org complaining when you execute this dml).

Note that as this is anon apex, there is no class to extend using c_TestFactory, so you'll see that written everywhere...
```Apex
    // Check the org can find the profile, I'm paranoid
    System.debug(c_OrgSettings.profileIdByName('System Administrator'));

    // Set the general context / change the defaults:
    c_TestFactory.LanguageLocaleKey = 'sv';

    // Create some test data...

    // Create key users
    User adminUser = (User) c_TestFactory.make(c_TestFactory.Entity.ADMIN_USER, (sObject) new User(username = 'my_special_name@user.example.com', alias = 'admis'));
    User adminUser1 = (User) c_TestFactory.make(c_TestFactory.Entity.ADMIN_USER, (sObject) new User(username = 'my_special_name1@user.example.com', alias = 'admi1'));
    User adminUser2 = (User) c_TestFactory.make(c_TestFactory.Entity.ADMIN_USER, (sObject) new User(username = 'my_special_name2@user.example.com', alias = 'admi2'));

    System.debug(LoggingLevel.INFO, '@@ '+ adminUser.username);
    System.debug(LoggingLevel.INFO, '@@ '+ adminUser.email);
    System.debug(LoggingLevel.INFO, '@@ '+ adminUser.LanguageLocaleKey);

    System.debug(LoggingLevel.INFO, '@@ '+ c_TestFactory.makers.get(c_TestFactory.Entity.ADMIN_USER).get().size());
    System.debug(LoggingLevel.INFO, '@@ '+ c_TestFactory.makers.get(c_TestFactory.Entity.ADMIN_USER).get());

    System.SavePoint s = Database.setSavepoint();
    c_TestFactory.run();
    
    // Check out my users inserted
    User[] users = [select id,name from user];
    System.debug(LoggingLevel.INFO, '@@ '+users);
    Database.rollback(s);
    //*/
```

