/**
* File Name   : c_TestFactory_SalesCloud
* Description : TestFactory Framework, provides templates and automation of data for use in unit tests
* Modification Log
* ============================================================================
* Ver   Date        Author                  Modification
*-----------------------------------------------------------------------------
* 0.1   7-12-2018   Matt Evans              Draft
*
* The class shows how to use the test framework by creating atomic and composite objects for the Sales Cloud.
*
* Each Business Object is registed in the TestFactory's "Entity" ENUM with a suitable label, and the label is then mapped to the Maker class in the "makers" map like this:
*
* public enum Entity {
*   //...The order is important, as it defines the order of the DML
*   ,SALES_ACCOUNT
*   ,SALES_CONTACT
*   ,CUSTOMER
*   //...Add more here as you go...
* }
*
* public static final Map<Entity, c_TestFactory> makers = new Map<Entity, c_TestFactoryData>{
*   //...Map your Entity labels to their maker class here...
*   ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
*   ,Entity.SALES_CONTACT  => new c_TestFactory_SalesCloud.SalesContact()
*   ,Entity.CUSTOMER  => new c_TestFactory_SalesCloud.Customer()
*   //...Add more here as you go...
* }
*/

public class c_TestFactory_SalesCloud {

    /*** Atomic Data; ex. a single User, Account, Contact *** /

    /*** Sales Account ***/

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


    public class SalesContact extends c_TestFactoryMaker {

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


    public class Customer extends c_TestFactoryMaker {

        // Mandatory minimum default set up, returns null as the Customer is more complex than a single sObject
        sObject defaults() {
            return null;
        }

        // Custom override for the maker
        public override sObject make(sObject sourceObject) {
            System.debug(LoggingLevel.debug, '@@ Custom maker method for a composite object @@');

            // Create an account
            c_TestFactoryMaker accountMaker = new SalesAccount();
            sObject defaultAccount = accountMaker.make(new Account(name = 'Basic Customer'));

            // Merge default values into passed object
            sourceObject = mergeFields( defaultAccount, sourceObject);

            // Append the account to the list of objects created by the method
            add(sourceObject);

            // Create contacts for the account
            Integer contactsToCreate = 2;// TODO: c_OrgSettings.BULKIFY_TESTS ? 201 : 2;

            for (Integer i = 0; i<contactsToCreate; i++)
            {
                c_TestFactoryMaker contactMaker = new SalesContact();
                sObject aContact = contactMaker.make(new Contact(Account = (Account) sourceObject, FirstName = 'Example', LastName = 'Contact '+i, Email= 'samplecustomer_'+i+'@donotsend.example.com'));

                // Append the Contact to the list of objects created by the method
                add(aContact);
            }

            // Add others... Cases or whatever make up a customer

            // Return the passed Account object

            return sourceObject;
        }
    }
//*/
}