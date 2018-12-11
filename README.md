# SFDC Enterprise Test Framework

## About
This project provides a way to centralise test data generation and reuse to all developers to:

- Rapidly scaffold a data set for a unit test, re-using previous examples from other developers. Speeding up development time and enables test driven development.
- Default objects (both 'atomic' or compound collections of sObjects) are provided by business case that can be re-used and customised by unit tests
- Represent the same sObject with different business cases ex. a Sales Account versus a Corporate Account (same sObject, different business purpose, so different data needs)
- Easily Extend to new Business OBjects, maximise re-use, and minimise merge conflicts
- Automate data generation in an efficient way, minimising DML cycles by grouping together similar object types and respecting the order of execution when generating data so that relationships are maintained
- Provide a central location to fix object definition changes that affect multiple tests. When a change is made, it's good that tests fail! And it's even better that there is one place to fix the code.
- Allow a Bulk data volume switch to be used by unit tests. It's important to test code at bulk, but once it's been tested it also slows down the org and deployment. Instead, develoeprs can use a flag to switch from genrating massive amounts of bulk data to a small number of records.

## Why use a test framework?
One major problem in Enterprise scale Salesforce projects is they are often riddled with bugs caused by Apex being written without clear test cases (ie. no Test Driven Development). Partly due to debugging in Apex being a very poor experience, developers often ship code that only has test coverage (the minimum 75%) that doesn't really test the intended outcome. 

Why, in the modern world is it like this? Well, in part it is because generating data for testing a data driven platform is a massive pain, especially in an agile project environment where the data surfaces of sObjects, security, profiles and users rapidly changes. One change can cause spaghetti, so developers keep things simple, which unfortunately results in problems later down the line when they also find out their code doesn't merge or work in real life.

The solution is to have a consistent place to manage and create this data. Basic approaches used by project developers include providing a set of methods that generate common data structures such as users, or Accounts - which works fine for simple enviornments. However dependencies and DML limits soon become an issue, and developers being indepependant minds tend to create multiple versions of the same method - eventually causing the same issue.

## In Use
### Optional Dependencies
The framework introduces a custom setting for managing Bulk data volumes (a switch) and a common class for handling this as an overall Org Setting. I would encourage this to be tailored to suit the destination org, but not to remove it. Managing common org settings and set up from a global class allows excellent chances for DRY code that mnimises the excess Apex tends to generate.

### Implementation
#### Objects
- TestSetUp__c - Custom setting containing the "Use Large Data Set In Test" flag

#### Classes
- OrgSettings - Contians the static reference to the Bulkification "switch"
- TestFactory - Contains the context for the test (country, locale etc., what ever is important for your org), and accessors to the business object templates. When ever these accessors are called, the results are added to memory and when "run" is called, they are committed to the database in one go.
- TestFactoryData - Interface stating what a maker class should implement so that the factory knows what it can call
- TestFactoryData_Users - Example implementation of two Users using standard salesforce profiles
- TestFactoryData_Sales - Example implementation of Sales data, an Account, a Contact and a "Customer" (a customer is an Account with child Contacts)
- TestFactory_Sample_Test_Class - an example test class with pseudo code

#### Setting up your data structures
1. Install the custom setting (default values FALSE), OrgSettings (refactor later if required), and the other classes.
2. Definte a set of classes to group data by, ex. Users, Sales, Service, Community and create a TestFactoryData_XXX class for each (use the examples provided to help)
3. Create your template methods by copying the sample code for your data objects that your tests will need
4. Wire then up to the TestFactory by updating the list of business objects and map them to the constructor of each template you created (see TestFactory class comments for instructions, it's two lines, very easy). Start with one and go from there, it's quite easy.
5. Write your tests, creating data in the TestSetup, see the example test class provided which guides you with comments on the recommended style.

#### Tour the example
You can create objects from the templates directly, or via the factory class. Doing it via the TestFactory means you can automate the generation of the data.

The example show how to use the factory to generate an admin user, some group level accounts, and then customer accounts who sit under their corporate group level. Nesting is an important technique required and often hard to get right in data creation:

```Apex
    // Set the general context for the factory to use. These can be referenced by the maker classes. Very useful in multilanguage and global text contexts:
    
    TP_TestFactory.countryName = 'Uruguay';
    TP_TestFactory.countryCode = 'UR';

    // Creating some test data...

    // Create key users
    User adminUser = (User) make(Entity.ADMIN_USER, new User(username = 'my_special_name@user.example.com', alias = 'admis'));

    // Create Accounts (high level accounts)
    Account[] topLevelList = new Account[]{
    };

    Integer owningAccounts = TP_OrgSettings.BULKIFY_TESTS ? 20 : 1;
    for (Integer i; i < owningAccounts; i++) {
        Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account ' + i));
        topLevelList.add(a);
    }

    run(); // Upsert all data queued so far. We need the top level account id's to create their child customer records...

    // Create customers (low level accounts - with child contacts)
    for (Account topLevel : topLevelList) {
        Integer customers = TP_OrgSettings.BULKIFY_TESTS ? 11 : 2;
        for (Integer i; i < customers; i++) {
            make(Entity.BASIC_CUSTOMER, new Account(name = 'Account ' + i, Parent = topLevel));
        }
    }

    run(); // Upsert the lower level customers (accounts and contacts)
```


#### Creating an object Directly from a template:
If you want to side step the factory, for what ever reason, you can. Simply reference the maker class directly. You can build your own factory if you want.

```Apex
  // Using the example class containing the SalesAccount example
  
  // Insantiate the maker, and then call the make method to get back an Account with default values
  TestFactoryData mySalesAccounts = new TestFactoryData_Example.SalesAccount();
  Account a = (Account) mySalesAccounts.make(new Account());
  
  System.assertEquals(a.Name, 'A Customer Account');
  System.assertEquals(mySalesAccounts.get().size(), 1); // a reference to the created account is kept in the SalesAccount object
  
  for (Integer i; i<10; i++)
  {
    mySalesAccounts.make(new Account(name='Another account '+i));
  }
  
  System.assertEquals(mySalesAccounts.get().size(), 11); // a reference to each created account is kept in the SalesAccount object
  
  insert (Account[]) mySalesAccounts.get();
```

## Q&A
### Ideas for improvement
One part that this project overlaps to is the OrgSettings area, and automation control for example (ie blocking and working with triggers, validation rules and process buider at scale). It could also overlap to error handling and reporting too, and include the new EventBus delivery methods as well as DML. Now that would be cool.

### Is it really a framework?
Technically not, though it does have interfaces that madate certain footprints and coding styles, it is more of a 'pattern'; however this repo can be used directly as base code and extended easily, so the answer is also 'Yes'. Other examples of frameworks in apex include Kevin O'Hara's excellent Light Weight Trigger Framework.

### I want to improve it and have decided to refactor the lot
Cool, if it's a major refactor make a pull request still, I want to see this kept simple but definately haven't spent much time considering different form factors for the approach.
