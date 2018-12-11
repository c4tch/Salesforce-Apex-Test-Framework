# SFDC Test Framework for Mid to Enterprise scale Project teams

## About
This project provides a way to centralise test data generation and reuse to all developers to:

- Rapidly scaffold a data set for a unit test, re-using previous examples from other developers. Speeding up development time and enables test driven development.
- Objects and collections (both 'atomic' or compound collections of sObjects) are provided by business case that can be re-used and customised by unit tests
- Easily Extend to new Business OBjects, maximise re-use, and minimise merge conflicts / overwrites
- Automate data generation in an efficient way, minimising DML cycles by grouping together similar object types and respecting the order of execution when generating data so that relationships are maintained
- Maintain a central location to fix object definition changes that affect multiple tests. When a change is made, it's good that tests fail! And it's even better that there is one place to fix the code.
- Allow a Bulk data volume switch to be used by unit tests. It's important to test code at bulk, but once it's been tested it also slows down the org and deployment. Instead, develoeprs can use a flag to switch from genrating massive amounts of bulk data to a small number of records.

## Why use a test framework?
One major problem in Enterprise scale Salesforce projects is they are often riddled with bugs caused by Apex being written without clear test cases (ie. no Test Driven Development). Partly due to debugging in Apex being a very poor experience, developers often ship code that only has test coverage (the minimum 75%) that doesn't really test the intended outcome. 

Why, in the modern world is it like this? Well, in part it is because generating data for testing a data driven platform is a massive pain, especially in an agile project environment where the data surfaces of sObjects, security, profiles and users rapidly changes. One change can cause spaghetti, so developers keep things simple, which unfortunately results in problems later down the line when they also find out their code doesn't merge or work in real life.

The solution is to have a consistent place to manage and create this data. Basic approaches used by project developers include providing a set of methods that generate common data structures such as users, or Accounts - which works fine for simple enviornments. However dependencies and DML limits soon become an issue, and developers being indepependant minds tend to create multiple versions of the same method - eventually causing the same issue.

## In Use
The framework works by providing a factory that allows developers to create buiness objects based on use cases for their unit tests. They are built out using default templates that can be tailored to the unit test being written, and then executed with efficient use of DML. 

Developers can write a business object once and reuse it throughout the org, extending it and creating variants for projects over time but without creating different footprints for every project and code initiative, allowing for refactoring and efficient use of DML in tests.

### Optional Dependencies
The framework introduces a custom setting for managing Bulk data volumes (a switch) and a common class for handling this as an overall Org Setting. I would encourage this to be tailored to suit the destination org, but not to remove it. Managing common org settings and set up from a global class allows excellent chances for DRY code that mnimises the excess Apex tends to generate.

### Implementation

#### Classes
Three main classes
- c_OrgSettings
- c_TestFactory
- c_TestFactoryMaker

And implementation examples:
- c_TestFactory_Users
- c_TestFactory_SalesCloud
- c_TestFactory_zzz_SampleUnitTest

Details:
- c_OrgSettings / Contians the static reference to the Bulkification "switch" (see c_TestSetup__mtd)

- c_TestFactory / Contains the context (country, locale etc., what ever is important for your org), and accessors to the business object makers. When ever these accessors are called, the results are added to memory and when "run" is called, they are committed to the database in one go.

- c_TestFactoryMaker / Abstract class stating what a maker class should implement so that the factory knows what it can call, and provides basic core methods

- c_TestFactory_Users / Example implementation of an Admin User using standard salesforce profiles

- c_TestFactory_SalesCloud / Example implementation of Sales Cloud data, an Account, a Contact and a "Customer" (a customer is an Account with child Contacts)

- c_TestFactory_zzz_SampleUnitTest / an example test class with pseudo code

#### Objects
- c__TestSetUp__mtd - Custom metadata containing the "Use Large Data Set In Test" flag

#### Setting up your data structures
1. Install the custom metadata (default values FALSE), OrgSettings (refactor later if required), and the other classes.
2. Definte a set of classes to group data by, ex. Users, Sales, Service, Community and create a c_TestFactory_XXX class for each (use the examples provided to help) that extends c_TestFactoryMaker
3. Create your template methods by copying the sample code for your data objects that your tests will need
4. Wire them up to the TestFactory by updating the "Entity" list with each object and the "makers" to map them to the constructor of each maker class you created.
5. Write your tests, creating data in the TestSetup, see the example test class provided which guides you with comments on the recommended style.

Tip to save time when creating a new Entity / "business object" - Create the maker class first, then run the following code (udpated to your new references) in Anon apex to check it's creating the default values correctly:

```Apex
    // note that if the test class extends c_TestFactory, we don't need to put c_TestFactory. everywhere, making the code much neater

    // Set the general context / change the defaults:
    c_TestFactory.LanguageLocaleKey = 'sv';

    // Check my new maker class to build an admin user...

    // Create admin user
    User adminUser = (User) c_TestFactory.make(c_TestFactory.Entity.ADMIN_USER, (sObject) new User(username = 'my_special_name@user.example.com', alias = 'ad1'));

    // Check out the result of the maker, it is a simple one, so I should see my custom values added as well as defaults like ProfileId
    System.debug(LoggingLevel.INFO, '@@ '+ adminUser.username);
    System.debug(LoggingLevel.INFO, '@@ '+ adminUser.email);
    System.debug(LoggingLevel.INFO, '@@ '+ adminUser.LanguageLocaleKey);
    System.debug(LoggingLevel.INFO, '@@ '+ adminUser.ProfileId);

    // Create two more using the factory
    c_TestFactory.make(c_TestFactory.Entity.ADMIN_USER, (sObject) new User(username = 'my_second_name@user.example.com', alias = 'ad2'));
    c_TestFactory.make(c_TestFactory.Entity.ADMIN_USER, (sObject) new User(username = 'my_third_name@user.example.com', alias = 'ad3'));

    // Check out the full list the factory will referr to when it inserts the records
    System.debug(LoggingLevel.INFO, '@@ '+ c_TestFactory.makers.get(c_TestFactory.Entity.ADMIN_USER).get().size());
    System.debug(LoggingLevel.INFO, '@@ '+ c_TestFactory.makers.get(c_TestFactory.Entity.ADMIN_USER).get());

    // Run the factory with a save point and rollback so I don't corrupt the good data in my org
    System.SavePoint s = Database.setSavepoint();
    c_TestFactory.run();
    User[] users = [select id,name from user];
    System.debug(LoggingLevel.INFO, '@@ '+users);
    Database.rollback(s);
    //*/
```

#### Tour the example
You can create objects from the templates directly, or via the factory class. Doing it via the TestFactory means you can automate the generation of the data.

The example show how to use the factory to generate an admin user, some group level accounts, and then customer accounts who sit under their corporate group level. Nesting is an important technique required and often hard to get right in data creation:

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
If you want to side step the factory, for what ever reason, you can. Simply reference the maker class directly. You can build your own factory if you want. Don't forget to extend the wrapping class with c_TestFactory to save you haveing to write c_TestFactory... every time

Insantiate the maker directly, and then call the "make" method to get back an Account with default values:
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
Cool, if it's a major refactor make a pull request still, I want to see this kept simple but definately haven't spent much time considering different form factors for the approach.

### How can I quickly validate my Maker Classes when I write them
Use some anonimous apex, here's an example I wrote after creating the AdminUser maker class to test it out (note there may be limits in your org on the number of Administrator licences, so watch for the org complaining when you execute this dml)

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

