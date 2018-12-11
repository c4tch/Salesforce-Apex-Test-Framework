/**
* File Name   : c_TestFactory_zzz_SampleUnitTest
* Description : Demo using the TestFactory Framework
* Modification Log
* ============================================================================
* Ver   Date        Author                  Modification
*-----------------------------------------------------------------------------
* 0.1   7-12-2018   Matt Evans              Draft
* 
*/

@isTest
public class c_TestFactory_zzz_SampleUnitTest extends c_TestFactory {

    @TestSetup
    public static void setUp() {
        // Set the general context / change the defaults:
        c_TestFactory.LanguageLocaleKey = 'sv';

        // Create some test data...

        // Create key users
        User adminUser = (User) make(Entity.ADMIN_USER, new User(username = 'my_special_name@user.example.com', alias = 'admis'));
        System.assertEquals(adminUser.username, 'my_special_name@user.example.com', 'Custom user name ignored');
        System.assertEquals(adminUser.LanguageLocaleKey, c_TestFactory.LanguageLocaleKey, 'Factory context for language locale key ignored');
        run();

        // Using the admin user, generate content
        System.runAs(adminUser)
        {
            // Create Accounts (high level accounts)
            Account[] topLevelList = new Account[]{
            };

            Integer owningAccounts = c_OrgSettings.BULKIFY_TESTS() ? 20 : 1;
            for (Integer i; i < owningAccounts; i++) {
                Account a = (Account) make(Entity.SALES_ACCOUNT, new Account(name = 'Top Level Account ' + i));
                topLevelList.add(a);
            }
            System.assert(topLevelList.size()==owningAccounts, 'Top level group accounts not generated');

            run(); // Upsert all data queued so far. We need the top level account id's to create their child customer records...

            // Create customers (low level accounts - with child contacts)
            for (Account topLevel : topLevelList) {
                Integer customers = c_OrgSettings.BULKIFY_TESTS() ? 11 : 2;
                for (Integer i; i < customers; i++) {
                    make(Entity.CUSTOMER, new Account(name = 'Account ' + i, Parent = topLevel));
                }
            }
            System.assert((c_TestFactory.makers.get(Entity.CUSTOMER)).get().size()>0, 'Child accounts not created');
            run(); // Upsert the lower level customers (accounts and contacts)
        }
    }

    @isTest
    public static void test_DataSetUp() {
        // Query for each data item
        // System.Assert they have been generated correctly
    }

    @isTest
    public static void test_UserStory() {
        // Query for data from TestSetup
        // Test: RunAs in context of relevant user for positive case with System.Assert
        // Test: RunAs in context of relevant user for negaive case with System.Assert
        // Once passing, call other methods that require the same data set where possible (reduces DML churn and time for tests to run)
    }
}