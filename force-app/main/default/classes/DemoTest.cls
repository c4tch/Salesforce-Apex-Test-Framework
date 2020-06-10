/**
 @Name: DemoTest.cls
 @TestedBy: Demos use of the Test Factory for a package
 @Description:
  Part 1) Create some objects to be used by your package, in this case an imaginary Sales Cloud project
  Part 2) Some demo tests (usually kept in another class) using the test objects
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
        c_TestFactory.setDefaultContext();

        User setUpUser = (User) c_TestFactory.make(new c_TestFactory_StandardUsers.UnitTestSetUpUser());

        c_TestFactory.run(); 

        System.runAs(setUpUser) {
            // Making an account hierarchy
            // - Build some Top Level Accounts

            Account[] topLevelList = new List<Account>();
            integer totalParentAccounts = c_TestFactory.BULKIFY_TESTS ? 100 : 2;
            integer totalCustomersPerTopAccount = 2;

            for (Integer i=0; i < totalParentAccounts; i++) {

                // You can create an account with child objects like this. We will add some more children to these to create a complex hierachy.
                Account a = (Account) c_TestFactory.make( new DemoObjects.DemoSalesAccount(), new Account(name = 'Top level ' + i));
                Contact c = (Contact) c_TestFactory.make( new DemoObjects.DemoSalesContact(), new Contact(FirstName = 'George', LastName = 'Boy' + i, Account = a));
                Opportunity o = (Opportunity) c_TestFactory.make( new DemoObjects.DemoSalesOpportunity(), new Opportunity(name='Opty ' + i, Account = a));

                // A simple account with nothing else (we wont make these parents)
                Account b = (Account) c_TestFactory.make( new DemoObjects.DemoSalesAccount(), new Account(name = 'Extra Account ' + i));
                
                topLevelList.add(a);
            }

            // Check everything makes sense
            System.assertEquals(totalParentAccounts, topLevelList.size(), 'Top level group accounts not generated');

            // Upsert all data queued so far. 
            // - We need the top level accounts to create their child records or the DML will get confused. 
            // - This is only the case when referencing the same sObject type in one dml transaction...
            c_TestFactory.run(); 

            // Build some complex Customers using the Customer example object (Accounts with contacts and optys)
            for (Account topLevel : topLevelList) {
                for (Integer i=0; i < totalCustomersPerTopAccount; i++) {
                    // To create a complex object, like a complete customer this can be done also:
                    c_TestFactory.make(new DemoObjects.DemoCustomer(), new Account(name = topLevel.name + ' Customer ' + i, ShippingCity='City'+i, Parent = topLevel));
                }
            }

            // Upsert the lower level customers (accounts and contacts)
            c_TestFactory.run(); 
        }
    }

    @IsTest
    static void demoTest() {
        c_TestFactory.setDefaultContext();
        Test.startTest();
        
        // Go query for your constructed objects and run a test
        
        Test.stopTest();
        
    }
    //*/
}