/**
 @Name: DemoTest.cls
 @TestedBy: Demos use of the Test Factory for a package
 @Description:
  Part 1) Set Up
  Part 2) Some demo test
 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       Draft 
*/

@IsTest
public class DemoTest extends c_TestFactory {
    /***
     * Demo using the DemoObjects availale
     */

    @TestSetup
    static void demoTestSetUp(){
        // Set the global context, so language etc. is consistent
        setDefaultContext();

        // Create a TestUser for inserting data.
        // -------------------------------------
        // This is a nice work around to allow tests to prevent process builders, triggers and flows from
        // firing. The Test Factory has a profile 'Test Factory Data Creator'. Attach a permission set
        // to this and apply Custom Permissions in configurtation. Then you can test for $Permission in the
        // prcoess builder or trigger you want to stop from firing when this user is run.
        // This work around signifficantly reduces DML and makes it much easier to intert large volumes of data
        // and also speeds up tests signifficantly.  
        User setUpUser = (User) make(c_TestFactoryStandardUsers.UnitTestSetUpUser.class);

        run(); 

        // Now make data
        System.runAs(setUpUser) {

            // Making an account hierarchy
            // - Build some Top Level Accounts

            Account[] topLevelList = new List<Account>();
            integer totalParentAccounts = c_TestFactory.BULKIFY_TESTS ? 100 : 2;
            integer totalCustomersPerTopAccount = 2;

            for (Integer i=0; i < totalParentAccounts; i++) {

                // You can create an account with child objects like this. We will add some more children to these to create a complex hierachy.
                Account a = (Account) make( DemoObjects.DemoSalesAccount.class, new Account(name = 'Top level ' + i));
                Contact c = (Contact) make( DemoObjects.DemoSalesContact.class, new Contact(FirstName = 'George', LastName = 'Boy' + i, Account = a));
                Opportunity o = (Opportunity) make( DemoObjects.DemoSalesOpportunity.class, new Opportunity(name='Opty ' + i, Account = a));

                // A simple account with nothing else (we wont make these parents)
                Account b = (Account) make( DemoObjects.DemoSalesAccount.class, new Account(name = 'Extra Account ' + i));
                
                topLevelList.add(a);
            }

            // Check everything makes sense
            System.assertEquals(totalParentAccounts, topLevelList.size(), 'Top level group accounts not generated');

            // Upsert all data queued so far. 
            // - We need the top level accounts to create their child records or the DML will get confused. 
            // - This is only the case when referencing the same sObject type in one dml transaction...
            run(); 

            // Build some complex Customers using the Customer example object (Accounts with contacts and optys)
            for (Account topLevel : topLevelList) {
                for (Integer i=0; i < totalCustomersPerTopAccount; i++) {
                    // To create a complex object, like a complete customer this can be done also:
                    make(DemoObjects.DemoCustomer.class, new Account(name = topLevel.name + ' Customer ' + i, ShippingCity='City'+i, Parent = topLevel));
                }
            }
            
            run(); 
        }
    }

    @IsTest
    static void demoTest() {
        setDefaultContext();
        Test.startTest();
        
        // Go query for your constructed objects and run a test
        
        Test.stopTest();
        
    }

    // Running a test without the need for DML
    // - To avoid running into issues such as CPU or DML limits when running tests the following practice is recommended
    // - 1) Create a user story and test the overall function of your code in bulk one use case at a time
    // - 2) If several operation occurr on every transaction, try to merge tests into one User functional process test
    // - 3) If a function performs no DML, or the data in/out doesnt require data in the database, then you can use the test framework without using RUN(), and use the sObjects as they are. You can put these in a class with no SetUp too.
    @isTest
    public static void testWithoutDML() {
        // Set the context to the same as set up
        setDefaultContext();

        Account a = (Account) make(DemoObjects.DemoSalesAccount.class, new Account(Name = 'No need to insert'));
        // No need to call run() as we just need the object shape, not database entry
        // Boolean myResult = myMethodToTest(a);
        // System.assert(myResult, 'My method failed');
    }
    //*/
}