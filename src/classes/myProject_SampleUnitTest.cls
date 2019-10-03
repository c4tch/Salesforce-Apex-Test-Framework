
/**
 @Name: myProject_SampleUnitTest.cls
 @OtherClasses: c_TestFactory
 @Tests: Demo using the test framework in unit tests
 @Description:
  1. Demo using the TestFactory Framework
 @Usage:
  Use the SetUp method to create objects using the test framework. 
  Make sure you use asserts to ensure the framework is perfoming as expected.

 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       25/08/2019      Initial pattern
  1.1         Matt Evans       2/10/2019       Tested with Bulkified volumes
*/

@isTest
public class myProject_SampleUnitTest extends c_TestFactory {
    
    // Bulkify or not? Look at the settings on the TestFactory to decide how much data to build
    static Integer totalParentAccounts = c_TestFactory.BULKIFY_TESTS ? 20 : 2;
    static Integer totalChildAccounts = c_TestFactory.BULKIFY_TESTS ? 11 : 2;

    @TestSetup
    static void setUp(){
        
        // Set the general context / change the defaults, country values etc. !important! 
        // This makes sure our data and our unit tests all use the same basic values

        c_TestFactory.setDefaultContext();

        // Make an admin user

        User adminUser = (User) make(Entity.ADMIN_USER, new User(alias = 'admis'));
        System.assertEquals(adminUser.alias, 'admis', 'Alias ignored when creating a user');
        System.assertEquals(adminUser.LanguageLocaleKey, c_TestFactory.LANGUAGE_LOCALE_KEY, 'Factory context for language locale key ignored');

        // Make a country user
        
        User countryUser = (User) make(Entity.COUNTRY_USER, new User(alias = 'ctry1'));
        System.assertEquals('ctry1', countryUser.alias, 'Alias ignored when creating a user');
        String expectedUserName = 'ctry1@'+ UserInfo.getOrganizationId() + '.test.com';
        System.assertEquals(expectedUserName, countryUser.username, 'Username not updated with the alias');
        System.assertEquals(c_TestFactory.LANGUAGE_LOCALE_KEY, countryUser.LanguageLocaleKey, 'Factory context for language locale key ignored');


        // Build Top Level Accounts
        
        Account[] topLevelList = new List<Account>();

        for (Integer i=0; i < totalParentAccounts; i++) {
            Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top level ' + i));
            topLevelList.add(a);
        }
        System.assertEquals(totalParentAccounts, topLevelList.size(), 'Top level group accounts not generated');

        // Upsert all data queued so far. We need the top level accounts to create their child records or the DML will get confused. This is only the case when referencing the same sObject type in one dml transaction...
        run(); 

        // Build Customers (accounts with contacts and optys), and parent then to the top level

        for (Account topLevel : topLevelList) {
            for (Integer i=0; i < totalChildAccounts; i++) {
                make(Entity.CUSTOMER, new Account(name = topLevel.name + ' Customer ' + i, ShippingCity='City'+i, Parent = topLevel));
            }
        }

        // Upsert the lower level customers (accounts and contacts)
        run(); 
    }

    // TEST SET UP DATA
    // Always have this method in a test so that you can be sure the set up works correctly
    @isTest
    public static void testSetUp() {        
        // Set the context to the same as set up
        c_TestFactory.setDefaultContext();

        // Query for each data item created in Set Up
        Account[] accounts = [Select id,name from Account];
        Contact[] contacts = [Select id,name from Contact];
        Opportunity[] opportunities = [Select id,name from Opportunity];

        // System.Assert they have been generated correctly
        System.assertEquals(totalParentAccounts + totalParentAccounts * totalChildAccounts, accounts.size(), 'Did not find correct numnber of inserted accounts');
        System.assertEquals(2 * totalParentAccounts * totalChildAccounts, contacts.size(), 'Did not find correct numnber of inserted contacts');
        System.assertEquals(2 * totalParentAccounts * totalChildAccounts, opportunities.size(), 'Did not find correct numnber of inserted opportunities');
    }

    // EXAMPLE USER STORY TEST
    @isTest
    public static void countryUserCanSeeAllAccounts() {
        // Set the context to the same as set up
        c_TestFactory.setDefaultContext();

        User countryUser = [select id,username,alias from User where alias='ctry1' limit 1];

        System.runAs(countryUser)
        {
            Account[] accounts = [Select id,name from Account];
            System.assertEquals(totalParentAccounts + totalParentAccounts * totalChildAccounts, accounts.size(), 'Country user could not retreive all account records');
        }
    }
    //*/
}