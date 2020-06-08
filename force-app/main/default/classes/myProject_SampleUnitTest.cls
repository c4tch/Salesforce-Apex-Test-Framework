/**
 * @File Name          : myProject_SampleUnitTest.cls
 * @Description        : 
 * @Author             : Matthew Evans
 * @Group              : 
 * @Last Modified By   : Matthew Evans
 * @Last Modified On   : 12/18/2019, 11:02:33 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    12/17/2019   Matthew Evans     Initial Version
**/

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
  TO BE UPDATED!
*/

@isTest
public class myProject_SampleUnitTest extends c_TestFactory {
    /*
    // Bulkify or not? Look at the settings on the TestFactory to decide how much data to build
    static Integer totalParentAccounts = c_TestFactory.BULKIFY_TESTS ? 20 : 2;
    static Integer totalChildAccounts = c_TestFactory.BULKIFY_TESTS ? 11 : 2;

    @TestSetup
    static void setUp(){
        
        // Set the general context / change the defaults, country values etc. !important! 
        // - This makes sure our data and our unit tests all use the same basic values

        c_TestFactory.setDefaultContext();

        // Makeing a user

        User adminUser = (User) make(Entity.ADMIN_USER, new User(alias = 'admis'));
        System.assertEquals(adminUser.alias, 'admis', 'Alias ignored when creating a user');
        System.assertEquals(adminUser.LanguageLocaleKey, c_TestFactory.LANGUAGE_LOCALE_KEY, 'Factory context for language locale key ignored');

        // Make a custom user
        // - ex. a template could be created for a Country Manager, mapped to COUNTRY_USER in TestFactory.
        
        User countryUser = (User) make(Entity.COUNTRY_USER, new User(alias = 'ctry1'));
        System.assertEquals('ctry1', countryUser.alias, 'Alias ignored when creating a user');
        String expectedUserName = 'ctry1@'+ UserInfo.getOrganizationId() + '.test.com';
        System.assertEquals(expectedUserName, countryUser.username, 'Username not updated with the alias');
        System.assertEquals(c_TestFactory.LANGUAGE_LOCALE_KEY, countryUser.LanguageLocaleKey, 'Factory context for language locale key ignored');

        // Making an account hierarchy
        // - Build Top Level Accounts
        
        Account[] topLevelList = new List<Account>();

        for (Integer i=0; i < totalParentAccounts; i++) {
            Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top level ' + i));
            topLevelList.add(a);
        }
        System.assertEquals(totalParentAccounts, topLevelList.size(), 'Top level group accounts not generated');

        // Upsert all data queued so far. We need the top level accounts to create their child records or the DML will get confused. 
        // - This is only the case when referencing the same sObject type in one dml transaction...
        run(); 

        // Build some complex Customers using the Customer example object (Accounts with contacts and optys) provided by the framework
        // - Instantiate them and parent them to the top level. Note that this only comumes one DML per object type, thus keeping your DML consumption under control when creating large amounts of data.

        for (Account topLevel : topLevelList) {
            for (Integer i=0; i < totalChildAccounts; i++) {
                make(Entity.CUSTOMER, new Account(name = topLevel.name + ' Customer ' + i, ShippingCity='City'+i, Parent = topLevel));
            }
        }

        // Upsert the lower level customers (accounts and contacts)
        run(); 
    }

    // TEST SET UP DATA
    // - Always have a method like this in a test so that you can be sure the set up works correctly
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
    // - To avoid running into issues such as CPU or DML limits when running tests the following practice is recommended
    // - 1) Create a user story and test the overall function of your code in bulk one use case at a time
    // - 2) If several operation occurr on every transaction, try to merge tests into one User functional process test
    // - 3) If a function performs no DML, or the data in/out doesnt require data in the database, then you can use the test framework without using RUN(), and use the sObjects as they are. 
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