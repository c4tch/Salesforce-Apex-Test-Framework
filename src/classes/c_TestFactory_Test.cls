/**
 @Name: c_TestFactory_Test.cls
 @Testing: c_TestFactory, c_TestAutomation, c_TestFactoryMaker, c_TestFactory_CoreUsers
 @Description: Registry of Business Objects 
 - The Test Factory package. 
 - Should NOT test the objects you create for your own projects! Create a separate test class for those.

 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       1/11/2019       Initial draft
*/

public class c_TestFactory_Test {

    public enum Entity {
        // Entities only used for Testing
        TEST_USER, TEST_ACCOUNT, TEST_CONTACT
    }

    public class 

    /*
    Test tempaltes
    */
    class testUser extends c_TestFactoryMaker {
        sObject defaults() {
            // Default object
            User rec = new User();
            String orgId = UserInfo.getOrganizationId();
            
            // Default values
            rec.Alias = 'SysAdmin';
            rec.UserName = rec.Alias + '@'+ orgId+'.anytest.com';
            rec.ProfileId = profileIdByName('Standard User');

            rec.Email = rec.Alias + '@any.test.com';
            rec.FirstName = 'Admin';
            rec.LastName = 'User';

            rec.EmailEncodingKey = EMAIL_ENCODING_KEY; // Context values taken from the Factory
            rec.LanguageLocaleKey = LANGUAGE_LOCALE_KEY;
            rec.LocaleSidKey = LOCALE_SID_KEY;
            rec.TimeZoneSidKey = TIMEZONE_SID_KEY;

            return (sObject) rec;
        }
    }
    
    public class testAccount extends c_TestFactoryMaker {
         // Mandatory minimum default set up, returns an sObject, in this case a default Account for the Sales Cloud
        sObject defaults() {

            // Default object
            Account rec = new Account();

            // Default values
            rec.Name = 'A Customer Account';
            rec.ShippingStreet = 'Nr 1 Some Street';
            rec.ShippingPostalCode = '11111';
            rec.ShippingCity = 'A City';
            rec.ShippingCountry = COUNTRY_NAME;

            return (sObject) rec;
        }
    }

    public class testContact extends c_TestFactoryMaker {

        // Mandatory minimum default set up, returns an sObject, in this case a default Contact for the Sales Cloud
        sObject defaults() {
            // Default object
            Contact rec = new Contact();

            rec.FirstName = 'Uri';
            rec.LastName = 'Steck';
            rec.Email = 'thegreatest@climber.example.com';
            
            return (sObject) rec;
        }
    }

    /*
    Unit Tests
    */
    @IsTest
    setContext() {
        setDefaultContext();

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
        User u = c_TestFactory.make(c_TestFactory.Entity.STANDARD_USER);
        System.assertEquals(c_TestFactory.LANGUAGE_LOCALE_KEY,u.LanguageLocaleKey, 'Locale key not set on standard user');
    }

    @IsTest
    genericTestFactoryMaker() {
        setDefaultContext();

        // Loop Entities, create one of each. 
        c_TestFactory.Entity = new enum MyEnum {
        }

        // Map the sObject type of each. 
        // Identify a key relation (User, Account, Contact) and map to the sObject type.
        // Check the getDefault operation, used for cloning 
        // Using the sObject type of each Entity, create a new set, merging field operation
        // Run the DML and confirm objects where created
        // If a key relation has been mapped, attempt to create a related pair
        // Create the pair and run. This will test for both mixed dml operations and also the id relationship construction.
        // Validate the relationship ID's survive
    }

    @IsTest
    testFactoryMaker() {
        setDefaultContext();

        // Makes sure we can create business object templates
        c_TestFactoryMaker mkr = new testUser();

        // Create an object and check the maker interface is working as expected
        // ...Make
        mkr.make(new User(LastName = 'TestUser'));

        // ...Check and manipulate the list of 'made' objects after running the make command
        System.Assert(mkr.get().size()==1, 'Test User object was not added to the stack');
        System.AssertEquals('TestUser', mkr.pop().get('LastName'), 'Test user was not added to the stack properly');
        System.AssertEquals('TestUser', mkr.pop().get('LastName'), 'Test user was not added to the stack properly');
        mkr.clear();
        System.AssertEquals(0, mkr.get().size()), 'Stack was not cleared when requested');
        
        // ...Get Defaults, useful when cloning settings
        User u = new User();
        u = (User)c_TestFactoryMaker.mergeFields(mkr.getDefaults(),(sobject)u);
        System.AssertEquals('TestUser', u.LastName, 'Maker did not return defaults as expected');
    }

    @IsTest
    mergeFields() {
        // Merge field from one instance of an object into another
        Account source = new Account(Name = '1234');
        Account destination = new Account(Phone = '5678');

        // Merge null fields
        destination = (Account)c_TestFactoryMaker.mergeFields((sobject)source,(sobject)destination);
        System.assertEquals('1234', destination.Name, 'Name field not merged');
        System.assertEquals('5678', destination.Phone, 'Name field not merged');

        // Do not overwrite populated fields (default behaviour)
        source.Name = 'zzzaaa';
        destination = (Account)c_TestFactoryMaker.mergeFields((sobject)source,(sobject)destination);
        System.assertNotEquals('zzzaaa', destination.Name, 'Name field was overwritten when it should have been left alone');        

        // Force overwrite populated fields
        destination = (Account)c_TestFactoryMaker.mergeFields((sobject)source,(sobject)destination,true);
        System.assertEquals('zzzaaa', destination.Name, 'Name field was not overwritten when it should have been');        
    }

    @IsTest 
    profileIdByName(){
        // I can get the ID of a profile by name
        Profile p = [select id, Name from Profile limit 1];
        System.AssertEqualds(r.Id, c_TestFactoryMaker.profileIdByName(r.Name),'Role ID not retreived for role "'+r.Name+'"');
    } 

    @IsTest
    roleIdByName() {
        // I can get the ID of a role by Name
        Role r = [select id,Name from Role limit 1];
        System.AssertEqualds(r.Id, c_TestFactoryMaker.roleIdByName(r.Name),'Role ID not retreived for role "'+r.Name+'"');
    }


    /*
    * Automation
    * Check the test factory by adding additional sample object templates (an Account with a Contact)
    * Simulate mixed dml and relationships
    */

    @IsTest()
    mixedDMLAndRelationships()
    {
        setDefaultContext();
        // Test that objects of different types can be inserted at the same time
        Account a = c_TestFactory.make(c_TestFactory.Entity.TEST_ACCOUNT, new Account(Name='AccountyMcCountFace'));
        Contact c = c_TestFactory.make(c_TestFactory.Entity.TEST_CONTACT, new Contact(LastName='McTestFace', Account = a));
        run();

        // Test that object relationships are maintained
        System.Assert(a.Id !=null, 'Account was not inserted');

        c = [select id, Name, AccountId from Contact limit 1 where id =:c.Id];
        System.AssertEquals(a.Id, c.AccountId, 'Contact was not inserted with Account Id set');
    }
}