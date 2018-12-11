# A Scalable Salesforce Apex Unit Test Framework
FAIR WARNING: This is the first commit :) Though it's based on several past projects; improvements and testing are yet to come. Give it a test-drive and let me know of issues.

## About
This project provides a way to centralise test data generation and promote reuse to all developers so that they can:

- Rapidly scaffold a unit test, and promote test driven development
- Create Objects and complex dependent collections, re-using previous examples from other developers and speed up development time, extend with minimal conflicts, maximise re-use, and minimise waste
- Automate data generation consistently, minimising DML cycles by grouping together similar object types, and mandate the order of execution when generating data so that relationships are maintained
- Side step the framework when necessary in a consistent way
- Maintain a central location to fix object definition changes that affect multiple tests (1) - critical in SIT testing
- Allow a Bulk data volume switch to be used by unit tests (2) - critical when it comes to production deploys

(1) When a change is made, it's good that tests fail! And it's even better that there is one place to fix the code.
(2) It's important to test code at bulk, but once it's been tested it also slows down the org and deployment. Instead, develoeprs can use a flag to switch from genrating massive amounts of bulk data to a small number of records.

## Why use a test framework?
One major problem in Enterprise scale Salesforce projects is they are often riddled with bugs caused by Apex being written without clear test cases (ie. no Test Driven Development). Partly due to debugging in Apex being a very poor experience, but also due to the complex setup of data and hoops they have to jump through just to get to the state they are testing. In the end, developers often ship code that only has test coverage (the minimum 75%) that doesn't really test the intended outcome. 

Generating data for testing a data driven platform is a massive pain, especially in an agile project environment where the data surfaces of sObjects, security, profiles and users rapidly change. One change can cause spaghetti, so as developers try to keep things simple, which results in problems later down the line when they find out their code doesn't merge or work in real life situations. Data in tests is vital.

Basic approaches used by project developers include providing a set of methods that generate common data structures such as users, or Accounts - which works fine for simple enviornments. However as projects grow, and dependencies and DML limits become an issue, and developers need a consistent way to work together to save time and generate predictable data to work with in testing - test driven development, especially, demands this.

## In Use
The framework provides a factory that allows developers to create buiness objects on the fly. These are created based on use cases providing templates that can be tailored to the unit test being written, and then executed with efficient use of DML. 

This avoids creating different footprints for every project and code initiative, allowing for refactoring and efficient use of DML in tests.

### Implementation

#### Classes
Three main classes
- c_OrgSettings
- c_TestFactory
- c_TestFactoryMaker

Maker classes demoing the factory:
- c_TestFactory_Users
- c_TestFactory_SalesCloud


And implementation in a sample unit test:
- c_TestFactory_zzz_SampleUnitTest

Details:
- c_OrgSettings / Contians the static reference to the Bulkification "switch" (see c_TestSetup__mtd)

- c_TestFactory / Contains the context (country, locale etc., what ever is important for your org), and accessors to the business object makers. When ever these accessors are called, the results are added to memory and when "run" is called, they are committed to the database in one go.

- c_TestFactoryMaker / Abstract class stating what a maker class should implement so that the factory knows what it can call, and provides basic core methods

- c_TestFactory_Users / Example implementation of an Admin User using standard salesforce profiles

- c_TestFactory_SalesCloud / Example implementation of Sales Cloud data, an Account, a Contact and a "Customer" (a customer is an Account with child Contacts)

- c_TestFactory_zzz_SampleUnitTest / an example test class with pseudo code


### Optional Dependencies
The framework introduces a custom metadata object for an option of when to use large data volumes in tests and a common class for handling this as an overall Org Setting. I would encourage this approach to be tailored / refactored to suit the destination org, but not to remove it. Managing common org settings and set up from a global class allows excellent chances for DRY code that mnimises the excess Apex tends to generate.

- c__TestSetUp__mtd - Custom metadata containing the "Use Large Data Set In Test" flag

## Create your own 'maker' templates
Objects are built using 'maker' classes, simple classes extending the c_TestFactoryMaker. This allows them to be hooked into the factory in a predictable way.

Creating a default object and allowing it to be populated by your own values in a unit test is rediculously easy.

As it's most basic, this is it:
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
The above declares a default set of values for a Sales Account. It's wrapped in a class to collect several of these together "SalesCloud"

This is then hooked up to the factory by adding the name to the "Entity" enum, and a reference to the "makers" map 
```Apex
public virtual class c_TestFactory {
    ...
    public enum Entity {
        ...
        ,SALES_ACCOUNT
        ...
    }
    
    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {
            //...
            ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
            //...
    };
    ...
}
```
(... denotes code you don't have to care about)

The Sales Account object is now available for use in all unit tests extending the factory class.

When a developer wants a Sales Account now they can use the factory. At the most basic this is two lines:
```Apex
public class myUnitTest extends c_TestFactory {
    make(Entity.SALES_ACCOUNT, (sObject) new Account(name = 'Roger Rabbit ACME Co.'));
    run(); //runs the DML
}
```

For a tip on how to quickly scaffold and test your maker class, see the Q&A sectoin at the end for some useful anon apex tips.

## Using the factory in a Unit Test

#### Tour the example
After setting up the code and custom meta data in an org, there is a Sample unit test showing the various ways you can consume the factory.

You can create objects from the factory, or directly from the maker classes. Doing it via the factory means you can automate the generation of the data.

The example tours the sample unit test so see how to use the factory to generate an admin user, some group level accounts, and then nested customer accounts who sit under their corporate group level. Nesting is an important technique required and often hard to get right in data creation:

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

Esencially it's only two lines again to reference a maker:

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

