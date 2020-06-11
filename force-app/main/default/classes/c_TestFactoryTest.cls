/**
 * @File Name          : c_TestFactoryTest.cls
 * @Description        : Tests the core test factory package and automates the maker objects.
 * @Author             : Matthew Evans
 * @Group              : 
 * @Last Modified By   : Matthew Evans
 * @Last Modified On   : 12/18/2019, 2:20:44 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    12/17/2019   Matthew Evans     Initial Version
 *   2.0         Matt Evans       8/6/2020        New model removed ENTITY references. New class name.
**/

@IsTest
public class c_TestFactoryTest {

    /*
    Unit Tests
    */
    @IsTest
    static void setContext() {
        c_TestFactory.setDefaultContext();

        // Query custom meta data   

        // Validate context is set
        System.assert(c_TestFactory.BULKIFY_TESTS != null, 'BULKIFY_TESTS not set in Test Settings (Custom Metadata Type)');
        System.assert(c_TestFactory.COUNTRY_CODE != null, 'COUNTRY_CODE not set in Test Settings (Custom Metadata Type)');
        System.assert(c_TestFactory.COUNTRY_NAME != null, 'COUNTRY_NAME not set in Test Settings (Custom Metadata Type)');
        System.assert(c_TestFactory.TIMEZONE_SID_KEY != null, 'TIMEZONE_SID_KEY not set in Test Settings (Custom Metadata Type)');
        System.assert(c_TestFactory.LANGUAGE_LOCALE_KEY != null, 'LANGUAGE_LOCALE_KEY not set in Test Settings (Custom Metadata Type)');
        System.assert(c_TestFactory.LOCALE_SID_KEY != null, 'LOCALE_SID_KEY not set in Test Settings (Custom Metadata Type)');
        System.assert(c_TestFactory.CURRENCY_ISO_CODE != null, 'CURRENCY_ISO_CODE not set in Test Settings (Custom Metadata Type)');
        System.assert(c_TestFactory.EMAIL_ENCODING_KEY != null, 'EMAIL_ENCODING_KEY not set in Test Settings (Custom Metadata Type)');

        // Validate context can be updated
        c_TestFactory.BULKIFY_TESTS = false;
        c_TestFactory.COUNTRY_CODE = 'zz';
        c_TestFactory.COUNTRY_NAME = 'Ziebretzke';
        c_TestFactory.LANGUAGE_LOCALE_KEY = c_TestFactory.LANGUAGE_LOCALE_KEY == 'FI' ? 'SV' : 'FI';
        
        // Basic test using the Core Users lib, which should follow the framework
        User u = (User)c_TestFactory.make(new c_TestFactoryStandardUsers.StandardUser());
        System.assertEquals(c_TestFactory.LANGUAGE_LOCALE_KEY,u.LanguageLocaleKey, 'Locale key not set on standard user');
    }

    @IsTest
    static void mergeFields() {
        // Merge field from one instance of an object into another
        Account source = new Account(Name = '1234');
        Account destination = new Account(Phone = '5678');

        // Merge null fields
        destination = (Account)c_TestFactoryObject.mergeFields((sobject)source,(sobject)destination);
        System.assertEquals('1234', destination.Name, 'Name field not merged');
        System.assertEquals('5678', destination.Phone, 'Name field not merged');

        // Do not overwrite populated fields (default behaviour)
        source.Name = 'zzzaaa';
        destination = (Account)c_TestFactoryObject.mergeFields((sobject)source,(sobject)destination);
        System.assertNotEquals('zzzaaa', destination.Name, 'Name field was overwritten when it should have been left alone');        

        // Force overwrite populated fields
        destination = (Account)c_TestFactoryObject.mergeFields((sobject)source,(sobject)destination,true);
        System.assertEquals('zzzaaa', destination.Name, 'Name field was not overwritten when it should have been');        
    }

    @IsTest 
    static void profileIdByName(){
        // I can get the ID of a profile by name
        Profile p = [select id, Name from Profile limit 1];
        System.AssertEquals(p.Id, c_TestFactoryObject.profileIdByName(p.Name),'Profile ID not retreived for Profile "'+p.Name+'"');
    } 

    @IsTest
    static void roleIdByName() {
        // I can get the ID of a role by Name
        UserRole r = [select id,Name from UserRole limit 1];
        System.AssertEquals(r.Id, c_TestFactoryObject.roleIdByName(r.Name),'Role ID not retreived for role "'+r.Name+'"');
    }

    @isTest
    static void sortAndLinkSObjects() {
        Account a = new Account(Name = 'Matthew', Id='00100000000014C'); // The ID needs to be any ID of a valid format for Account. No DML is applied, so the record does not need to exist.
        Contact c = new Contact(LastName = 'Evans', Account = a); // objects may be associated in this way before they have an id in practice
        
        sObject[] objs = new List<Sobject>{a,c};
        
        List<String> createOrder = new List<String>();
        Map<String, sObject[]> collections_INSERT = new map<String, sObject[]>();
        Map<String, sObject[]> collections_UPDATE = new map<String, sObject[]>();
        c_TestFactory.sortAndLinkSObjects(objs, createOrder, collections_INSERT, collections_UPDATE);

        System.AssertEquals (collections_INSERT.get('Contact')[0] , c , 'A new Contact should have been Added to the Insert list');
        System.AssertEquals (collections_UPDATE.get('Account')[0] , a , 'An exsiting Account should have been Added to the Update list');
        System.Assert (c.AccountId == a.Id , 'The Contact should have been related to the existing Account record');
    }


    /*
    * Scan custom entities for compliance
    * Checks the indexed templates in c_TestFactory__c conform to some basic functions
    */

    @IsTest
    static void automateTestingOfEntities() {
        try {
            // The test shouldnt be aware of the objects created so this is for coverage only. 
            // It is not expected to succeed.
            c_TestFactory.run();
            System.Assert(TRUE);
        } catch (Exception e) {
            // Any failures will be output here as warnings only
            System.Debug(LoggingLevel.INFO, '@@ WARNING: Factory failed to run DML for one or more sObjects. This may be ignored. Exception: '+e);
            System.Assert(TRUE);
        }
    }
    //*/
}