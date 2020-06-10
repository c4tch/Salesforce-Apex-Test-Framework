/**
 @Name: DemoObjects.cls
 @TestedBy: Demo creating objects using the Test Factory for use by a package or project code
 @Description:
  Provides some constructors for demo objects to be used by your package, 
  in this case some objects for an imaginary Sales Cloud project
 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       Draft 
*/
public class DemoObjects {
    
    /*** Sales Account ***/
    public class DemoSalesAccount extends c_TestFactoryObject {

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

    /*** Sales Contact ***/
    public class DemoSalesContact extends c_TestFactoryObject {

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
    
    /*** Sales Opty ***/
    public class DemoSalesOpportunity extends c_TestFactoryObject {

        // Mandatory minimum default set up, returns an sObject, in this case a default OPPORTUNITY for the Sales Cloud
        sObject defaults() {
            // Default object
            Opportunity rec = new Opportunity();

            rec.Name = 'An Oppty';
            rec.StageName  = 'Analyse';
            rec.CloseDate = System.today() + 90;
            
            return (sObject) rec;
        }
    }

    /**
    * Business Objects: Complete Customer... etc.
    **/
    public class DemoCustomer extends c_TestFactoryObject {

        // Default can return null for complex objects, the make method is the key part
        sObject defaults() {
            return null;
        }
        
        // Custom override for the maker
        public override sObject make(sObject sourceObject) {
            // Create an account
            Account customerAccount = (Account) c_Testfactory.make(new DemoObjects.DemoSalesAccount(), (Account)sourceObject);

            // We want some unique name for the child component emails etc. so strip the account name
            String cleanNameForRelatedRecords = customerAccount.name.replaceAll('[^a-zA-Z0-9]','');

            // Create contacts for the account and add them to the factory
            Integer contactsToCreate = 2;
            for (Integer i = 0; i<contactsToCreate; i++)
            {
                String contactFirstName = customerAccount.name;
                String contactUniqueEmail = cleanNameForRelatedRecords+'_'+i+'@donotsend.example.com';
                c_Testfactory.make(new DemoObjects.DemoSalesContact(), new Contact(Account = customerAccount, FirstName = contactFirstName, LastName = 'Contact '+i, Email = contactUniqueEmail));
            }

            // Create opportunties for the account and add them to the factory
            Integer opptysToCreate = 2;
            for (Integer i = 0; i<opptysToCreate; i++)
            {
                c_Testfactory.make(new DemoObjects.DemoSalesOpportunity(), new Opportunity(Account = customerAccount, Name = customerAccount.name +' Test Oppty '+i));
            }

            // Return the passed Account object as a root reference
            return (sObject) customerAccount;
        }
    }
    //*/
}