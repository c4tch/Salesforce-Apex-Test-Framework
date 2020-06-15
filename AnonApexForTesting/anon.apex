System.Savepoint s = Database.setSavepoint();

c_TestFactory.setDefaultContext();
User testUser = (User) c_TestFactory.make(new c_TestFactoryStandardUsers.UnitTestSetUpUser());

c_TestFactory.run();

// Test for multiple records of same type
Account a2 = (Account) c_TestFactory.make(DemoObjects.DemoSalesAccount.class, new Account(name = 'Account 2'));
Account a1 = (Account) c_TestFactory.make(DemoObjects.DemoSalesAccount.class, new Account(name = 'Account 1'));
Account a3 = (Account) c_TestFactory.make(DemoObjects.DemoSalesAccount.class, new Account(name = 'Account 3'));

// Test for associating multiple record of the same type to a record in the same factory transaction
Asset a = (Asset) c_TestFactory.make(DemoObjects.DemoAsset.class, new Asset(Account = a1, Account3__r = a3, Account2__r = a2));

c_TestFactory.run();
System.debug('@@ Class Test result');
System.debug(a1.Name);
System.debug(a2.Name);
System.debug(a3.Name);
System.debug(a);
System.debug(a.Account.Name);
System.debug(a.Account2__r.Name);
System.debug(a.Account3__r.Name);


/* / Making an account hierarchy
// - Build Top Level Accounts

Account[] topLevelList = new List<Account>();
integer totalParentAccounts = 50;
integer totalChildAccounts = 2;

for (Integer i=0; i < totalParentAccounts; i++) {
    Account a = (Account) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesAccount(), new Account(name = 'Top level ' + i));
    Contact c = (Contact) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesContact(), new Contact(FirstName = 'George', LastName = 'Boy' + i));
    Opportunity o = (Opportunity) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesOpportunity(), new Opportunity(name='Opty ' + i));
    Account b = (Account) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesAccount(), new Account(name = 'Extra Account ' + i));
    
    topLevelList.add(a);
}

System.assertEquals(totalParentAccounts, topLevelList.size(), 'Top level group accounts not generated');

// Upsert all data queued so far. We need the top level accounts to create their child records or the DML will get confused. 
// - This is only the case when referencing the same sObject type in one dml transaction...
c_TestFactory.run(); 

//*
// Build some complex Customers using the Customer example object (Accounts with contacts and optys) provided by the framework
// - Instantiate them and parent them to the top level. Note that this only comumes one DML per object type, thus keeping your DML consumption under control when creating large amounts of data.

for (Account topLevel : topLevelList) {
    for (Integer i=0; i < totalChildAccounts; i++) {
        c_TestFactory.make(new c_TestFactory_SalesCloud.Customer(), new Account(name = topLevel.name + ' Customer ' + i, ShippingCity='City'+i, Parent = topLevel));
    }
}

// Upsert the lower level customers (accounts and contacts)
//*/
Database.rollback(s);